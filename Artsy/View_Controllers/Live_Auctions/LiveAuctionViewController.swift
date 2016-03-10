import UIKit
import Artsy_UIButtons
import Artsy_UILabels
import Artsy_UIFonts
import FLKAutoLayout
import ORStackView
import Interstellar


class LiveAuctionViewController: UIViewController {
    let auctionDataSource = LiveAuctionSaleLotsDataSource()
    var salesPerson: LiveAuctionsSalesPersonType = LiveAuctionsSalesPerson()
    let scrollManager = ScrollViewProgressObserver()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        salesPerson.setupWithStub()
        auctionDataSource.salesPerson = salesPerson

        view.backgroundColor = .whiteColor()

        let navToolbar = UIView()
        view.addSubview(navToolbar)

        // TODO: make a smaller ARCircularActionButton?
        // Also this entire thing should become a view
        let buttons:[UIView] = ["chat", "lots", "info", "close"].map { name in
            let button = ARCircularActionButton(imageName: "\(name)_icon")
            return button
        }

        buttons.forEach { button in
            navToolbar.addSubview(button)
            button.constrainHeight("40")
            button.constrainWidth("40")
            button.layer.cornerRadius = 20;
        }

        UIView.spaceOutViewsHorizontally(buttons, predicate: "8")
        buttons.last?.alignTopEdgeWithView(navToolbar, predicate: "0")
        buttons.last?.alignTrailingEdgeWithView(navToolbar, predicate:"0")
        buttons.first?.alignLeadingEdgeWithView(navToolbar, predicate: "0")
        UIView.alignTopAndBottomEdgesOfViews(buttons)

        // 30 because there's no statusbar
        navToolbar.alignTopEdgeWithView(view, predicate: "30")
        navToolbar.alignTrailingEdgeWithView(view, predicate: "-10")
        navToolbar.constrainHeight("40")

        // This sits _behind_ the PageViewController, which is transparent and shows it through
        // meaning interaction is dealt with elsewhere
        let previewView = LiveAuctionImagePreviewView(signal: scrollManager.progress, salesPerson: salesPerson)
        view.addSubview(previewView)
        previewView.backgroundColor = .debugColourRed()
        previewView.constrainHeight("200")
        previewView.constrainTopSpaceToView(navToolbar, predicate: "10")
        previewView.alignLeadingEdgeWithView(view, predicate: "0")
        previewView.alignTrailingEdgeWithView(view, predicate: "0")

        let pageController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: [:])
        pageController.dataSource = auctionDataSource
        ar_addModernChildViewController(pageController)

        let startVC = auctionDataSource.liveAuctionPreviewViewControllerForIndex(0)
        pageController.setViewControllers([startVC!], direction: .Forward, animated: false, completion: nil)

        if let scrollView = pageController.view.subviews.filter({ $0.isKindOfClass(UIScrollView.self) }).first as? UIScrollView {
            scrollView.delegate = scrollManager
        }

        let pageControllerView = pageController.view
        pageControllerView.constrainTopSpaceToView(navToolbar, predicate: "0")
        pageControllerView.alignLeadingEdgeWithView(view, predicate: "0")
        pageControllerView.alignTrailingEdgeWithView(view, predicate: "0")
        pageControllerView.alignBottomEdgeWithView(view, predicate: "0")

        let progress = SimpleProgressView()
        progress.progress = 0.6
        progress.backgroundColor = .artsyLightGrey()

        view.addSubview(progress)
        progress.constrainHeight("4")
        progress.alignLeading("0", trailing: "0", toView: view)
        progress.alignBottomEdgeWithView(view, predicate: "-165")
    }

    // Support for ARMenuAwareViewController

    let hidesBackButton = true
    let hidesSearchButton = true
    let hidesStatusBarBackground = true
}

class LiveAuctionSaleLotsDataSource : NSObject, UIPageViewControllerDataSource {
    var salesPerson: LiveAuctionsSalesPersonType!

    func liveAuctionPreviewViewControllerForIndex(index: Int) -> LiveAuctionLotViewController? {
        let auctionVC =  LiveAuctionLotViewController()
        guard let viewModel = salesPerson.lotViewModelForIndex(index) else { return nil }
        auctionVC.lotViewModel.update(viewModel)
        auctionVC.auctionViewModel.update(salesPerson.auctionViewModel)
        auctionVC.index = index
        return auctionVC
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if salesPerson.auctionViewModel.lotCount == 1 { return nil }

        guard let viewController = viewController as? LiveAuctionLotViewController else { return nil }
        var newIndex = viewController.index - 1
        if (newIndex < 0) { newIndex = salesPerson.auctionViewModel.lotCount - 1 }
        return liveAuctionPreviewViewControllerForIndex(newIndex)
    }


    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if salesPerson.auctionViewModel.lotCount == 1 { return nil }

        guard let viewController = viewController as? LiveAuctionLotViewController else { return nil }
        let newIndex = (viewController.index + 1) % salesPerson.auctionViewModel.lotCount;
        return liveAuctionPreviewViewControllerForIndex(newIndex)
    }
}


class LiveAuctionBidHistoryViewController: UITableViewController {
    let lotViewModel = Signal<LiveAuctionLotViewModel>()
    let auctionViewModel = Signal<LiveAuctionViewModel>()

    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

class LiveAuctionLotViewController: UIViewController {
    var index = 0
    let lotViewModel = Signal<LiveAuctionLotViewModel>()
    let auctionViewModel = Signal<LiveAuctionViewModel>()

    override func viewDidLoad() {
        super.viewDidLoad()

        let metadataStack = ORStackView()
        metadataStack.bottomMarginHeight = 0
        view.addSubview(metadataStack)
        metadataStack.alignBottomEdgeWithView(view, predicate: "-72")
        metadataStack.constrainWidthToView(view, predicate: "-40")
        metadataStack.alignCenterXWithView(view, predicate: "0")

        let artistNameLabel = UILabel()
        artistNameLabel.font = UIFont.serifSemiBoldFontWithSize(16)
        metadataStack.addSubview(artistNameLabel, withTopMargin: "0", sideMargin: "20")

        let artworkNameLabel = ARArtworkTitleLabel()
        artworkNameLabel.setTitle("That work", date: "2006")
        metadataStack.addSubview(artworkNameLabel, withTopMargin: "0", sideMargin: "20")

        let estimateLabel = ARSerifLabel()
        estimateLabel.font = UIFont.serifFontWithSize(14)
        estimateLabel.text = "Estimate: $100,000–120,000 USD"
        metadataStack.addSubview(estimateLabel, withTopMargin: "2", sideMargin: "20")

        let premiumLabel = ARSerifLabel()
        premiumLabel.font = UIFont.serifFontWithSize(14)
        premiumLabel.text = "Buyer’s Premium 25%"
        premiumLabel.alpha = 0.3
        metadataStack.addSubview(premiumLabel, withTopMargin: "2", sideMargin: "20")

        let infoToolbar = LiveAuctionToolbarView()
        metadataStack.addSubview(infoToolbar, withTopMargin: "40", sideMargin: "20")
        infoToolbar.constrainHeight("14")

        let bidButton = ARBlackFlatButton()
        metadataStack.addSubview(bidButton, withTopMargin: "14", sideMargin: "20")

        let currentLotView = LiveAuctionCurrentLotView()
        metadataStack.addSubview(currentLotView, withTopMargin: "14", sideMargin: "20")

        // might be a way to "bind" these?
        auctionViewModel.next { auctionViewModel in
            if let currentLot = auctionViewModel.currentLotViewModel {
                currentLotView.viewModel.update(currentLot)
            }

            if auctionViewModel.saleAvailability == .Closed {
                metadataStack.removeSubview(currentLotView)
            }
        }

        lotViewModel.next { vm in
            artistNameLabel.text = vm.lotArtist
            artworkNameLabel.setTitle(vm.lotName, date: "1985")
            estimateLabel.text = vm.estimateString
            infoToolbar.lotVM = vm
            bidButton.setTitle(vm.bidButtonTitle, forState: .Normal)

            switch vm.lotState {
            case .ClosedLot:
                bidButton.setEnabled(false, animated: false)


            case .LiveLot:
                // We don't need this when it's the current lot
                metadataStack.removeSubview(currentLotView)

            case .UpcomingLot(_):
                print("OK")
            }
        }
    }
}


/// This is a proof of concept, needs more work ( needs far left / far right views for example
/// and to deal with transforms/ opacity

class LiveAuctionImagePreviewView : UIView {
    let salesPerson: LiveAuctionsSalesPersonType
    let progress: Signal<CGFloat>
    var leftImageView, rightImageView, centerImageView: UIImageView

    init(signal: Signal<CGFloat>, salesPerson: LiveAuctionsSalesPersonType) {
        self.salesPerson = salesPerson
        self.progress = signal

        leftImageView = UIImageView(frame: CGRectMake(0, 0, 140, 140))
        centerImageView = UIImageView(frame: CGRectMake(0, 0, 140, 140))
        rightImageView = UIImageView(frame: CGRectMake(0, 0, 140, 140))

        leftImageView.backgroundColor = UIColor.debugColourPurple()
        centerImageView.backgroundColor = UIColor.debugColourPurple()
        rightImageView.backgroundColor = UIColor.debugColourPurple()

        super.init(frame: CGRect.zero)

        [leftImageView, centerImageView, rightImageView].forEach { self.addSubview($0) }

        signal.next { progress in
            let width = Int(self.bounds.width)
            let half = Int(width / 2)

            self.leftImageView.center = self.positionOnRange(-half...half, value: progress)
            self.centerImageView.center = self.positionOnRange(0...width, value: progress)
            self.rightImageView.center = self.positionOnRange(half...width + half, value:  progress)
        }
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        progress.update(1)
    }

    func valueOnRange(range: Range<Int>, value: CGFloat) -> CGFloat {
        let min = CGFloat(range.minElement()!)
        let max = CGFloat(range.maxElement()!)

        let midpoint = (min + max) / 2
        let offset: CGFloat
        if value == 0 {
            offset = 0
        } else if value > 0 {
            offset = (max - midpoint) * value
        } else {
            offset = (midpoint - min) * value
        }
        return midpoint + offset
    }

    func transformOnRange(range: Range<Int>, value: CGFloat) -> CGAffineTransform {
        let zoomLevel = valueOnRange(range, value: value)
        return CGAffineTransformScale(CGAffineTransformIdentity, zoomLevel/100, zoomLevel/100);
    }

    func positionOnRange(range: Range<Int>, value: CGFloat) -> CGPoint {
        let x = valueOnRange(range, value: value)
        return CGPoint(x: x, y: bounds.height / 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class LiveAuctionCurrentLotView: UIView {

    let viewModel = Signal<LiveAuctionLotViewModel>()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .artsyPurple()

        let liveLotLabel = ARSansSerifLabel()
        liveLotLabel.font = .sansSerifFontWithSize(12)
        liveLotLabel.text = "Live Lot"

        let artistNameLabel = UILabel()
        artistNameLabel.font = .serifSemiBoldFontWithSize(16)

        let biddingPriceLabel = ARSansSerifLabel()
        biddingPriceLabel.font = .sansSerifFontWithSize(16)

        let hammerView = UIImageView(image: UIImage(named:"lot_bidder_hammer_white"))
        let thumbnailView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))


        [liveLotLabel, artistNameLabel, biddingPriceLabel, thumbnailView, hammerView].forEach { addSubview($0) }
        [liveLotLabel, artistNameLabel, biddingPriceLabel].forEach {
            $0.backgroundColor = backgroundColor
            $0.textColor = .whiteColor()
        }

        constrainHeight("54")

        // Left Side

        thumbnailView.alignLeadingEdgeWithView(self, predicate: "10")
        thumbnailView.constrainWidth("38", height: "38")
        thumbnailView.alignCenterYWithView(self, predicate: "0")

        liveLotLabel.constrainLeadingSpaceToView(thumbnailView, predicate: "10")
        liveLotLabel.alignTopEdgeWithView(self, predicate: "10")

        artistNameLabel.constrainLeadingSpaceToView(thumbnailView, predicate: "10")
        artistNameLabel.alignBottomEdgeWithView(self, predicate: "-10")

        // Right side

        hammerView.alignTrailingEdgeWithView(self, predicate: "-10")
        hammerView.constrainWidth("32", height: "32")
        hammerView.alignCenterYWithView(self, predicate: "0")

        biddingPriceLabel.alignAttribute(.Trailing, toAttribute: .Leading, ofView: hammerView, predicate: "-12")
        biddingPriceLabel.alignCenterYWithView(self, predicate: "0")

        viewModel.next { vm in
            artistNameLabel.text = vm.lotArtist
            biddingPriceLabel.text = vm.currentLotValue
            thumbnailView.ar_setImageWithURL(vm.urlForThumbnail)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LiveAuctionToolbarView : UIView {
    // eh, not sold on this yet
    var lotVM: LiveAuctionLotViewModel!

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Remove all subviews and call setupViews() again to start from scratch.
        subviews.forEach { $0.removeFromSuperview() }
        setupViews()
    }


    func lotCountString() -> NSAttributedString {
        return NSAttributedString(string: "\(lotVM.lotIndex)/\(lotVM.lotCount)")
    }

    func attributify(string: String) -> NSAttributedString {
        return NSAttributedString(string: string)
    }

    func setupViews() {
        let viewStructure: [[String: NSAttributedString]]
        let clockClosure: (UILabel) -> ()

        switch lotVM.lotState {
        case .ClosedLot:
            viewStructure = [
                ["lot": lotCountString()],
                ["time": attributify("Closed")],
                ["bidders": attributify("11")],
                ["watchers": attributify("09")]
            ]
            clockClosure = { label in
                // do timer
                label.text = "00:12"
            }

        case .LiveLot:
            viewStructure = [
                ["lot": lotCountString()],
                ["time": attributify("00:12")],
                ["bidders": attributify("11")],
                ["watchers": attributify("09")]
            ]
            clockClosure = { label in
                // do timer
                label.text = "00:12"
            }

        case let .UpcomingLot(distance):
            viewStructure = [
                ["lot": lotCountString()],
                ["time": attributify("")],
                ["watchers": attributify("09")]
            ]

            clockClosure = { label in
                label.text = "\(distance) lots away"
            }
        }

        let views:[UIView] = viewStructure.map { dict in
            let key = dict.keys.first!
            let thumbnail = UIImage(named: "lot_\(key)_info")

            let view = UIView()
            let thumbnailView = UIImageView(image: thumbnail)
            view.addSubview(thumbnailView)

            let label = ARSansSerifLabel()
            label.font = UIFont.sansSerifFontWithSize(12)
            view.addSubview(label)
            if key == "time" {
                clockClosure(label)
            } else {
                label.attributedText = dict.values.first!
            }

            view.constrainHeight("14")
            thumbnailView.alignTop("0", leading: "0", toView: view)
            label.alignBottom("0", trailing: "0", toView: view)
            thumbnailView.constrainTrailingSpaceToView(label, predicate:"-6")
            return view
        }

        views.forEach { button in
            self.addSubview(button)
            button.alignTopEdgeWithView(self, predicate: "0")
        }

        let first = views.first!
        let last = views.last!

        first.alignLeadingEdgeWithView(self, predicate: "0")
        last.alignTrailingEdgeWithView(self, predicate: "0")

        // TODO do right via http://stackoverflow.com/questions/18042034/equally-distribute-spacing-using-auto-layout-visual-format-string

        if views.count == 3 {
            let middle = views[1]
            middle.alignCenterXWithView(self, predicate: "0")
        }
        if views.count == 4 {
            let middleLeft = views[1]
            let middleRight = views[2]
            middleLeft.alignAttribute(.Leading, toAttribute: .Trailing, ofView: first, predicate: "12")
            middleRight.alignAttribute(.Trailing, toAttribute: .Leading, ofView: last, predicate: "-12")
        }
    }
}

/// Handles passing out information about the scroll progress to others

class ScrollViewProgressObserver : NSObject, UIScrollViewDelegate {
    let progress = Signal<CGFloat>()

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let point = scrollView.contentOffset

        // Creates a value from -1 to 0 to 1
        let index = (point.x - scrollView.frame.width) / scrollView.frame.width * -1;
        progress.update(index)
    }
}

class SimpleProgressView : UIView {
    var highlightColor = UIColor.artsyPurple() {
        didSet {
            setNeedsDisplay()
        }
    }

    var progress: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }

    override func drawRect(rect: CGRect) {
        let bg = UIBezierPath(rect: bounds)
        backgroundColor!.set()
        bg.fill()

        let progressRect = CGRect(x: 0, y: 0, width: Int(bounds.width * progress), height: Int(bounds.height))
        let fg = UIBezierPath(rect: progressRect)
        highlightColor.set()
        fg.fill()
    }
}