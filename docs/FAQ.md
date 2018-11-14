# FAQ

## Why Multibase?

See the [Multibase](https://github.com/multiformats/multibase) or the README.

## Can I add an encoding?

I will not add an encoding that is not part of [Multibase](https://github.com/multiformats/multibase) as this is an implementation. In other words, I have no control over which encodings. Ask the Multibase maintainers.

## Can you use my encoder instead of one of the ones you are using?

If you want to do this, either fork this project or prove to me that your encoder is better in some way than the existing encoders. I strongly advise you to submit pull requests to any encoders used instead of rolling your own.

I will only consider encoders that:

* Generally conform to the Elixir `Base` module
* Generate any matching of characters at compile time, not runtime
* Are faster than existing encoders on average for real-world data for either encoding or decoding
    * Encoding and decoding implementations are independent, so it is possible to mix and match codecs for each
* Are documented and have tests + examples

## Why do I need this? it is faster to encode without Multibase.

Again, see the [Multibase](https://github.com/multiformats/multibase) or the README.

Encoding and decoding will naturally be slower as there are additional bytes and matching that need to happen.

## Best Practices?

* Encode using `encode!/1` or `encode/1`
    * It is better to encode the entire payload at once. The `multibase/2` function is only meant as an adapter per a feature request.
* Decode using `decode/1`, `decode!/1`, `codec_decode/1`, or `codec_decode!/1`
* Be wary of Base1 encoding. It is part of the Multibase standard, but essentially a meme.
* Encode only Elixir binaries that are not already encoded. Do not double encode.

## Can you add `insert feature`?

I am happy to add features, as long as they relate to the Multibase standard and do not deviate.     

## Why is data I encoded/decoded always a string?

The data is not necessarily a string, it is an Elixir binary. Depending on where you evaluate your code, it may be printed as a nice string, a series of bytes, or something else. See [Binaries, strings, and charlists](https://elixir-lang.org/getting-started/binaries-strings-and-char-lists.html).

## Did you optimize binaries?

Yes. This project is always compiled with `ERL_COMPILER_OPTIONS=bin_opt_info` to check for optimization opportunities. I cannot guarantee the behavior of all encoders, but any that I have authored and generally anything in `Base` has also done this.

## Can I remove encoders? Why did you pick these encoders?

No, you cannot remove Bases. If you really want to fork it and do so, the process is simple. I have included all encoders as specified by the Multibase standard, no more, no less. The goal of this library is simply to be compliant.