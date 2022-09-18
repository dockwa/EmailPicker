import UIKit

class EmailPickerCell: UITableViewCell {
    @objc static let height: CGFloat = 60
    static var reuseIdentifier: String {
        String(describing: self)
    }

    lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        return imageView
    }()
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(label)
        imageViewConstraints()
        labelConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func imageViewConstraints() {
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        let top = NSLayoutConstraint(item: thumbnailImageView,
                                     attribute: .top,
                                     relatedBy: .equal,
                                     toItem: contentView,
                                     attribute: .top,
                                     multiplier: 1,
                                     constant: 10)
        let leading = NSLayoutConstraint(item: thumbnailImageView,
                                         attribute: .leading,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .leading,
                                         multiplier: 1,
                                         constant: 10)
        let centerY = NSLayoutConstraint(item: thumbnailImageView,
                                         attribute: .centerY,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .centerY,
                                         multiplier: 1,
                                         constant: 0)
        let width = NSLayoutConstraint(item: thumbnailImageView,
                                        attribute: .width,
                                        relatedBy: .equal,
                                        toItem: nil,
                                        attribute: .notAnAttribute,
                                        multiplier: 1,
                                        constant: 40)
        thumbnailImageView.addConstraint(width)
        contentView.addConstraints([top, leading, centerY])
    }

    private func labelConstraints() {
        label.translatesAutoresizingMaskIntoConstraints = false
        let leading = NSLayoutConstraint(item: label,
                                         attribute: .leading,
                                         relatedBy: .equal,
                                         toItem: thumbnailImageView,
                                         attribute: .trailing,
                                         multiplier: 1,
                                         constant: 10)
        let centerY = NSLayoutConstraint(item: label,
                                         attribute: .centerY,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .centerY,
                                         multiplier: 1,
                                         constant: 0)
        contentView.addConstraints([leading, centerY])
    }
}
