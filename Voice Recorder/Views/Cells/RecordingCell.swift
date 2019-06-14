//
//  RecordingCell.swift
//  Voice Recorder
//
//  Created by Egor on 6/14/19.
//  Copyright © 2019 Egor. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RecordingCell: UITableViewCell {

    private var viewModel: RecordingCellViewModelling!
    private let disposeBag = DisposeBag()

    private let labelStack = UIStackView()
    private let buttonStack = UIStackView()

    private let titleLabel = UILabel()
    private let durationLabel = UILabel()

    private let progressView = UIProgressView()

    private let playbackButton = UIButton()
    private let deleteButton = UIButton()

    func setup() {
        setupLabels()
        setupButtons()
        setupProgress()
        setupConstraints()
    }

    private func setupConstraints() {

        labelStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().inset(16)
        }

        buttonStack.snp.makeConstraints { make in
            make.left.greaterThanOrEqualTo(labelStack)
            make.right.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }

        progressView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview()
        }
    }

    private func setupLabels() {
        contentView.addSubview(labelStack)
        [titleLabel, durationLabel].forEach(labelStack.addArrangedSubview)

        labelStack.spacing = 6
        labelStack.axis = .vertical
        labelStack.alignment = .fill

        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        durationLabel.font = .systemFont(ofSize: 14)

        titleLabel.numberOfLines = 0
        durationLabel.numberOfLines = 0
    }

    private func setupButtons() {

        contentView.addSubview(buttonStack)
        [playbackButton, deleteButton].forEach(buttonStack.addArrangedSubview)

        buttonStack.spacing = 12
        buttonStack.axis = .horizontal
        buttonStack.alignment = .fill

        playbackButton.setTitle("Play", for: [])
        playbackButton.setTitleColor(.black, for: [])

        deleteButton.setTitle("Delete", for: [])
        deleteButton.setTitleColor(.red, for: [])

        // Bindings
        let toggleSwitch = playbackButton.rx.controlEvent(.touchUpInside)
            .scan(false) { (v, _) in !v }
            .share(replay: 1, scope: .whileConnected)

        toggleSwitch
            .subscribe(viewModel.playbackToggleSubject)
            .disposed(by: disposeBag)

        toggleSwitch
            .map { isPlaying in isPlaying ? "Stop" : "Play" }
            .bind(to: playbackButton.rx.title())
            .disposed(by: disposeBag)

        deleteButton.rx.tap
            .subscribe(viewModel.deleteSubject)
            .disposed(by: disposeBag)
    }

    private func setupProgress() {
        contentView.addSubview(progressView)

        viewModel.progress
            .subscribe(onNext: { progress in
                self.progressView.progress = progress
            })
            .disposed(by: disposeBag)
    }

    func configureWith(_ viewModel: RecordingCellViewModelling) {
        self.viewModel = viewModel

        titleLabel.text = viewModel.creationDate
        durationLabel.text = viewModel.duration

        setup()
        layoutIfNeeded()
    }
}
