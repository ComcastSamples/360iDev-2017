# DemoSQL

This library provides a Swift interface to the [SQLite C library.](https://www.sqlite.org/) It is cross-platform compatible and currently builds for iOS, iOS simulator, and macOS.

## Database

The `Database` class exposes interfaces to prepare `Statement` objects or directly execute SQL statements.

## Statement

The `Statement` class allows binding objects and structs conforming to `DatabaseBindable` to SQL query parameters marked with '?'. It also exposes a `Cursor` struct which is used to iterate rows.

# DemoPlot

This library provides a very limited Swift interface to the [PLPlot C scientific plotting library.](http://plplot.sourceforge.net/) It currently only builds for macOS, as PLPlot depends on [Cairo](https://www.cairographics.org/) and other libraries.

It exposes the `drawHistrogram` function to render timeseries data as a histogram image.

## Installation

This library depends on plplot.dylib installed by homebrew. If you have homebrew installed, run the following command to install plplot.

```brew update && brew install plplot```

You can [install homebrew from its website.](https://brew.sh/)

# DemoPlayground.playground

This playground includes a sample SQLite database containing weather measurements taken from [the NOAA Climate Data Online service.](https://www.ncdc.noaa.gov/cdo-web/)
