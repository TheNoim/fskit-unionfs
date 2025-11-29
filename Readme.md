# UnionFS for [FSKit](https://developer.apple.com/documentation/FSKit)

This is a WIP implementation of an [UnionFS](https://en.wikipedia.org/wiki/UnionFS) driver for the newly available [FSKit](https://developer.apple.com/documentation/FSKit) in macOS.

### What is currently working?

- Only a very basic file tree
    > Files show up in finder and they show the correct attributes. But reading/writing/moving/renaming/creating a file or directory is not implemented yet.
- Very basic tests

### Plans

- Read/Write
- At the moment FSKit doesn't support displaying external changes. But I have plans to simulate external changes with an external process. I really hope we get an api for this next year. Therefore this will only be a temporary implementation.
- More and better test
- Basic UI for mounting and managing mounted unions
