//
//  WelcomeViewController.swift
//  PretixScan
//
//  Created by Daniel Jilg on 13.03.19.
//  Copyright © 2019 rami.io. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController, Configurable {
    var configStore: ConfigStore?

    @IBOutlet private weak var explanationLabel: UILabel!
    @IBOutlet private weak var checkmarkDetailLabel: UILabel!
    @IBOutlet private weak var continueButton: UIButton!
    @IBOutlet private weak var acceptSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Localization.WelcomeViewController.Title
        explanationLabel.text = Localization.WelcomeViewController.Explanation
        checkmarkDetailLabel.text = Localization.WelcomeViewController.CheckMarkDetail
        continueButton.setTitle(Localization.WelcomeViewController.Continue, for: .normal)
    }

    // MARK: - Actions
    @IBAction private func accept(_ sender: Any) {
        continueButton.isEnabled = acceptSwitch.isOn
    }

    @IBAction private func `continue`(_ sender: Any) {
        guard let configStore = self.configStore else { return }
        configStore.welcomeScreenIsConfirmed = true
        dismiss(animated: true, completion: nil)
    }
}
