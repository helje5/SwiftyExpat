// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SwiftyExpat",
    products: [
        .library(name: "Expat",       targets: [ "Expat"       ]),
        .library(name: "SwiftyExpat", targets: [ "SwiftyExpat" ])
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "Expat",       dependencies: [ ],
                cSettings: [
                  .define("HAVE_EXPAT_CONFIG_H")
                ]),
        .target(name: "SwiftyExpat", dependencies: [ "Expat" ])
    ]
)
