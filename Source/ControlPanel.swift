//
//  ControlPanel.swift
//  PlayerKit
//
//  Created by Hiroki Kumamoto on 9/12/15.
//
//

import Foundation
import SnapKit

public class ControlPanel: UIView {
    let paddingSide:        CGFloat = 10.0
    let paddingBottom:      CGFloat = 15.0
    let paddingBottomTime:  CGFloat = 5.0
    let buttonSize:         CGFloat = 40.0
    let buttonPadding:      CGFloat = 30.0

    public var slider:              UISlider!
    public var previousButton:      UIButton!
    public var playButton:          UIButton!
    public var nextButton:          UIButton!
    public var titleLabel:          UILabel!
    public var currentLabel:        UILabel!
    public var totalLabel:          UILabel!

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initializeSubviews()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeSubviews()
    }

    public func createSubviews() {
        titleLabel     = UILabel()
        currentLabel   = UILabel()
        totalLabel     = UILabel()
        slider         = UISlider()
        nextButton     = UIButton(type: UIButtonType.System)
        playButton     = UIButton(type: UIButtonType.System)
        previousButton = UIButton(type: UIButtonType.System)
    }

    public override func updateConstraints() {
        super.updateConstraints()
        currentLabel.snp_makeConstraints { make in
            make.left.equalTo(self.snp_left).offset(self.paddingSide).priorityHigh()
            make.top.equalTo(self.snp_top).offset(self.paddingBottomTime)
        }
        totalLabel.snp_makeConstraints { make in
            make.right.equalTo(self.snp_right).offset(-self.paddingSide).priorityHigh()
            make.top.equalTo(self.snp_top).offset(self.paddingBottomTime)
        }
        slider.snp_makeConstraints { make in
            make.left.equalTo(self.snp_left).offset(self.paddingSide)
            make.right.equalTo(self.snp_right).offset(-self.paddingSide)
            make.top.equalTo(self.currentLabel.snp_bottom).offset(self.paddingBottom)
        }
        previousButton.snp_makeConstraints { make in
            make.right.equalTo(self.playButton.snp_left).offset(-self.buttonPadding)
            make.centerY.equalTo(self.playButton.snp_centerY)
            make.width.equalTo(self.buttonSize)
            make.height.equalTo(self.buttonSize)
        }
        playButton.snp_makeConstraints { (make) -> () in
            make.centerX.equalTo(self.snp_centerX)
            make.top.equalTo(self.slider.snp_bottom).offset(self.paddingBottom)
            make.width.equalTo(self.buttonSize * 3/5)
            make.height.equalTo(self.buttonSize * 3/5)
        }
        nextButton.snp_makeConstraints { make in
            make.left.equalTo(self.playButton.snp_right).offset(self.buttonPadding)
            make.centerY.equalTo(self.playButton.snp_centerY)
            make.width.equalTo(self.buttonSize)
            make.height.equalTo(self.buttonSize)
        }
        titleLabel.snp_makeConstraints { make in
            make.left.greaterThanOrEqualTo(self.snp_left).offset(self.paddingSide*6)
            make.right.greaterThanOrEqualTo(self.snp_right).offset(-self.paddingSide*6)
            make.centerX.equalTo(self.snp_centerX)
            make.top.equalTo(self.snp_top).offset(self.paddingBottomTime)
            make.bottom.equalTo(self.slider.snp_top).offset(self.paddingBottomTime)
        }
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.setNeedsUpdateConstraints()
    }

    public func initializeSubviews() {
        createSubviews()
        titleLabel.textColor     = UIColor.whiteColor()
        titleLabel.font          = UIFont.boldSystemFontOfSize(16)
        titleLabel.textColor     = UIColor.whiteColor()
        titleLabel.textAlignment = NSTextAlignment.Center
        currentLabel.textColor   = UIColor.whiteColor()
        currentLabel.font        = UIFont.boldSystemFontOfSize(15)
        totalLabel.textColor     = UIColor.whiteColor()
        totalLabel.font          = UIFont.boldSystemFontOfSize(15)

        nextButton.tintColor     = UIColor.whiteColor()
        playButton.tintColor     = UIColor.whiteColor()
        previousButton.tintColor = UIColor.whiteColor()

        let bundle = NSBundle(identifier: "io.kumabook.PlayerKit")
        let nextImage     = UIImage(named:     "next", inBundle: bundle, compatibleWithTraitCollection: nil)
        let playImage     = UIImage(named:     "next", inBundle: bundle, compatibleWithTraitCollection: nil)
        let previousImage = UIImage(named: "previous", inBundle: bundle, compatibleWithTraitCollection: nil)
        nextButton.setImage(        nextImage, forState: UIControlState())
        playButton.setImage(        playImage, forState: UIControlState())
        previousButton.setImage(previousImage, forState: UIControlState())

        backgroundColor = UIColor.darkGrayColor()
        clipsToBounds = true
        addSubview(titleLabel)
        addSubview(currentLabel)
        addSubview(totalLabel)
        addSubview(slider)
        addSubview(nextButton)
        addSubview(playButton)
        addSubview(previousButton)
    }
}