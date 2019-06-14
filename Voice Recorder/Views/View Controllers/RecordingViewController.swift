//
//  RecordingViewController.swift
//  Voice Recorder
//
//  Created by Egor on 6/12/19.
//  Copyright © 2019 Egor. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import SnapKit

class RecordingViewController: UIViewController {

    let viewModel: RecordingViewModelling
    let disposeBag = DisposeBag()

    // MARK: View components
    let tableView = UITableView()
    let recordButton = UIButton()
    let timeLabel = UILabel()

    // MARK: Initializers
    init(_ viewModel: RecordingViewModelling) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Livecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        makeBindings()
    }

    // MARK: Instance methods
    private func setupViews() {

        setupTableView()

        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 150))
        tableView.tableHeaderView = headerView

        // record button
        headerView.addSubview(recordButton)

        recordButton.setTitleColor(.blue, for: [])
        recordButton.setTitle("Start Recording", for: [])
        recordButton.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
        }

        // time label
        headerView.addSubview(timeLabel)
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .semibold)
        timeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(headerView).dividedBy(2)
        }
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            let safeArea = view.safeAreaLayoutGuide
            make.top.left.right.equalTo(safeArea)
            make.bottom.equalTo(view)
        }

        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.register(RecordingCell.self, forCellReuseIdentifier: "\(RecordingCell.self)")

        viewModel.cellDriver
            .drive(tableView.rx.items) { tableView, row, item in
                let cell = tableView.dequeueReusableCell(withIdentifier: "\(RecordingCell.self)") as! RecordingCell
                cell.configureWith(RecordingCellViewModel(item))
                return cell
            }
            .disposed(by: disposeBag)
    }

    private func makeBindings() {
        let toggleSwitch = recordButton.rx.controlEvent(.touchUpInside)
            .scan(false) { (v, _) in !v }
            .share(replay: 1, scope: .whileConnected)

        toggleSwitch
            .subscribe(viewModel.recordingToggleSubject)
            .disposed(by: disposeBag)

        toggleSwitch
            .map { $0 ? "Stop Recording" : "Start Recording" }
            .bind(to: recordButton.rx.title())
            .disposed(by: disposeBag)

        viewModel.recordingTimeRelay
            .map { value in
                String(format: "%02i:%02i", Int(value), Int(value.truncatingRemainder(dividingBy: 1) * 100))
            }
            .asDriver(onErrorJustReturn: "0")
            .drive(timeLabel.rx.text)
            .disposed(by: disposeBag)
    }
}
