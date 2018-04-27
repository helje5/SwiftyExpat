// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "SwiftyExpat",
    products: [
        .library   (name: "Expat",       targets: [ "Expat"       ]),
        .library   (name: "SwiftyExpat", targets: [ "SwiftyExpat" ])
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "Expat",       dependencies: [ ]),
        .target(name: "SwiftyExpat", dependencies: [ "Expat" ])
    ]
)
