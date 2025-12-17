import AppKit
import STTextView

let sonnet = """
A Sonnet for Seattle

Beneath the grey embrace of coastal skies,
Where mountains rise like sentinels of old,
The Emerald City wakes as daylight dies,
Its stories yet untold, its dreams of gold.

Pike Place awakens with the fisher's call,
Fresh salmon gleaming in the morning light,
The ferries glide where seagulls rise and fall,
Mount Rainier stands watch, majestic height.

The coffee houses brew their bitter art,
While rain falls soft upon the city streets,
Each drop a blessing to this northern heart,
Where ocean mist and mountain glory meets.

Through fog and drizzle, still the spirit soars,
This emerald gem upon Pacific shores.

---

The Space Needle pierces morning haze,
A monument to futures yet unseen,
While houseboats rock in Portage Bay's soft maze,
And Capitol Hill pulses evergreen.

The cherry blossoms burst on campus grounds,
At Washington where scholars learn and grow,
The underground tours show the buried towns,
Where pioneers once walked so long ago.

Ballard's locks lift boats from sea to lake,
The salmon ladder draws the tourists near,
Discovery Park trails twist and snake,
Through forest paths where deer appear.

Seattle stands where earth and ocean meet,
With rain-soaked soul and ever-moving feet.

---

From Fremont's troll beneath the bridge so wide,
To Gasworks Park where industry once reigned,
The neighborhoods spread out on every side,
Each quarter with its character maintained.

The Market's neon sign glows red at night,
First Starbucks stands where coffee culture grew,
The Great Wheel spins with colors bright,
Above the bay of deepest navy blue.

Tech towers rise where forests used to stand,
Amazon spheres like bubbles in the rain,
Yet still the mountains guard this precious land,
Where Native peoples' heritage remain.

This city built on seven hills divine,
Where evergreen and innovation twine.

---

The winters bring their endless gentle grey,
A cozy blanket wrapped around the town,
While summer sun makes everything okay,
When locals shed their flannel and their frown.

The kayaks dot the waters of the Sound,
The hikers climb to Rattlesnake's high ridge,
The buskers play their music all around,
Pike Place to Pioneer Square bridge.

The Seahawks roar in stadiums of blue,
The Mariners swing bats in summer heat,
The Sounders kick and the Kraken pursue,
Athletics making spirits feel complete.

Seattle lives between the sea and stone,
A Pacific Northwest wonder all its own.

---

Oh Seattle, city of my heart,
Where coffee flows like rain upon the street,
Where nature and technology both start,
To weave a tapestry both wild and sweet.

Your grey skies hold a beauty all their own,
Your people kind beneath their cool reserve,
In every neighborhood a seed is sown,
Of community that nothing can unnerve.

From Alki Beach to Magnolia's bluff,
From Georgetown's art to Ballard's Nordic pride,
This city proves that rain is not so tough,
When beauty spreads on every single side.

Forever may your emerald banner wave,
Seattle strong, Seattle bold and brave.
"""

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var textView: STTextView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "STTextView Content Insets Test"
        window.center()

        // Create STTextView with scroll view
        let scrollView = STTextView.scrollableTextView()
        textView = scrollView.documentView as? STTextView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.drawsBackground = true

        // Configure text view
        textView.font = NSFont.systemFont(ofSize: 16)
        textView.text = sonnet
        textView.isHorizontallyResizable = false // wrap text
        textView.highlightSelectedLine = true

        // KEY TEST: Set content insets
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets(
            top: 50,      // 50pt top margin
            left: 40,     // 40pt left margin
            bottom: 300,  // 300pt bottom for scroll-past-end
            right: 40     // 40pt right margin
        )

        // Also set line fragment padding for horizontal text inset
        textView.textContainer.lineFragmentPadding = 40

        // Add to window
        window.contentView?.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: window.contentView!.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor)
        ])

        window.makeKeyAndOrderFront(nil)

        print("Content insets set to: top=50, left=40, bottom=300, right=40")
        print("Line fragment padding: 40")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
