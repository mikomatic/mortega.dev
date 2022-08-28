---
title: "til: Generate a file with specific size in java"
date: 2022-05-10T20:35:54+02:00
tags: ["java", "junit","nio"]
categories: ["til"]
author: "@mikomatic"
---

Recently I put in place a new feature in our app that dealt with uploading file(s). It could we use a simple upload or a
multi-part upload to cloud storage.

Testing this feature required the creation of dummy tests files with specific size in order to trigger
(or not) the multi-part upload:

- Committing dummy files to our git repository was a definite no-no.
- Files should be thrown away after running the tests.
- Files creation should as fast as possible.
- The actual content of the file is not important.

Junit
5's [TempDirectory extension](https://junit.org/junit5/docs/current/user-guide/#writing-tests-built-in-extensions-TempDirectory)[^1]
resolved to first 2 bullet points:

The other requirements could be met with sparse files:

> Sparse files are files stored in a file system where consecutive data blocks consisting of all zero-bytes (null-bytes)
> are compressed to nothing. There is often no reason to store lots of empty data, so the file system just records how
> long the sequence of empty data is instead of writing it out on the storage media. This optimization can save
> significant amounts of storage space for other purposes.
>
> [source](https://www.ctrl.blog/entry/sparse-files.html)

The following code generate a sparse file, open the file for writing, seeks a given position and adds
some bytes at the end. It leverages the `FileChannel` class.

```java
@Test
void example(@TempDir Path tempFolder)throws IOException{
// The sparse option is only taken into account if the underlying filesystem
// supports it
final OpenOption[]options={
        StandardOpenOption.WRITE,
        StandardOpenOption.CREATE_NEW,
        StandardOpenOption.SPARSE};

final Path hugeFile=tempFolder.resolve("hugefile.txt");

        try(final SeekableByteChannel channel=Files.newByteChannel(hugeFile,options)){
        // or any other size
        long giB=1024L*1014L*1024L;
        channel.position(giB);

// Write some random bytes
final ByteBuffer buf=ByteBuffer.allocate(4).putInt(2);
        buf.rewind();
        channel.write(buf);
        }

        //Do something with my dummy file
        }
```

Since we don't need to actually allocate disk space, large sparse files can be created in a relative short time, making
a good fit for quick "unit" testing.

### Additional Resources:

- https://www.baeldung.com/junit-5-temporary-directory
- https://en.wikipedia.org/wiki/Sparse_file

[^1]: This feature is still experimental