# Multibase

This library is an Elixir implementation of [Multibase](https://github.com/multiformats/ex-multibase). It provides an Elixir-centric interface to [Multibase](https://github.com/multiformats/multibase) and several helper functions for making the process as painless as possible. Further, it aggregates a collection of clean, pragmatic, and reasonably fast (in Elixir terms) encoders and decoders.

Multibase provides a simple way of encoding data by tagging it with the given encoding method. This allows encoding and decoding safely and accurately within a known set of encodings. Multibase ensures that the encoding type is always known, human readable, and that data can be transparently encoded and decoded in a consistent way. 

In particular, multibase is especially relevant when sending data over a network and/or interacting with other programs. Instead of assuming or negotiating a convention for data manually, the intent is transmitted in-band. This facilitates quick, safe, and predictable changes should requirements such as encoding type or settings change. While not full-proof, Multibase offers a light-weight interface that eases debugging, testing, and multi-format handling.

From the Multibase README:

  Multibase is a protocol for distinguishing base encodings and other simple string encodings, and for ensuring full compatibility with program interfaces. It answers the question:

```
Given data d encoded into string s, how can I tell what base d is encoded with?
```

  Base encodings exist because transports have restrictions, use special in-band sequences, or must be human-friendly. When systems chose a base to use, it is not always clear which base to use, as there are many tradeoffs in the decision. Multibase is here to save programs and programmers from worrying about which encoding is best. It solves the biggest problem: a program can use multibase to take input or produce output in whichever base is desired. The important part is that the value is self-describing, letting other programs elsewhere know what encoding it is using.
  
  
Multibase prefixes data with a given base encoding identifier (a varint). The format is as follows:

```
<varint-base-encoding-code><base-encoded-data>
```
  
## Supported Encodings

The following table lists the currently supported Multibase encodings. All encodings (22) are currently supported by this library. Be aware that this list can and probably will be updated in the [Multibase](https://github.com/multiformats/multibase) spec.

Each encoding has an accompanying prefix code. An upper-case code signifies upper-encoding/decoding, and a lower-case code signifies a lower-case encoding/decoding.

  | encoding     |      code |  name                                                     | encoding ids                                   |
  |--------------|-----------|-----------------------------------------------------------|------------------------------------------------|
  | identity     |       0x00|  8-bit binary (encoder and decoder keeps data unmodified) |`:identity`                                     |
  | base1        |          1|     unary tends to be 11111                               |`:base1`                                        |
  | base2        |          0|     binary has 1 and 0                                    |`:base2`                                        |
  | base8        |          7|     highest char in octal                                 |`:base8`                                        |
  | base10       |          9|     highest char in decimal                               |`:base10`                                       |
  | base16       |        F,f|    highest char in hex                                    |`:base16_upper`, `:base16_lower`                |
  | base32hex    |        V,v|    rfc4648 no padding - highest char                      |`:base32_hex_upper`, `:base32_hex_lower`        |
  | base32hexpad |        T,t|    rfc4648 with padding                                   |`:base32_hex_pad_upper`, `:base32_hex_pad_lower`|
  | base32       |        B,b|    rfc4648 no padding                                     |`:base32_upper`, `:base32_lower`                |
  | base32pad    |        C,c|    rfc4648 with padding                                   |`:base32_pad_upper`, `:base32_pad_lower`        |
  | base32z      |          h|     z-base-32 - used by Tahoe-LAFS - highest letter       |`:base32_z`                                     |
  | base58flickr |          Z|     highest letter                                        |`:base58_flickr`                                |
  | base58btc    |          z|     highest letter                                        |`:base58_btc`                                   |
  | base64       |          m|     rfc4648 no padding                                    |`:base64`                                       |
  | base64pad    |          M|     rfc4648 with padding - MIME encoding                  |`:base64_pad`                                   |
  | base64url    |          u|     rfc4648 no padding                                    |`:base64_url`                                   |
  | base64urlpad |          U|     rfc4648 with padding                                  |`:base64_url_pad`                               |

Additional encodings can be added as necessary via a small update to a declarative map in the `Multibase` module.

## Why?

* Human-friendly encoding across multiple bases
    * Simpler debugging and auditing of encoded data
* Single consistent interface for encoding and decoding popular encodings in typical real-world Bases
    * Same functions for encoding and decoding all bases
    * Same return types for all functions regardless of encoding 
* Collection of benchmarked, reasonably fast, pragmatic, and consistent interface encoders and decoders
    * Manually rolled encodings where benefits exist
    * Avoids generic "BaseXXX" style encoding that can be error-prone, inefficient, or not one-size fits all for all bases
* Decode data without mental juggling of the encoding type from elsewhere in the code
* Work with technologies that use or support Multibase such as IPFS, CID, etc.
* Simplify encoding and decoding interfaces to negate need to pass options and other parameters to ensure the correct encoding values
    * Ex: No worries about forgetting to pass a `padding` or `case` parameter.  
* Data-driven approach for Bases
    * Simple map update to add a new Base at compile time
    * Easy to write adapters
    * Does not force you to even use the same encoder and decoder modules
    * Explicit
  
## Usage

Full API Documentation can be found at [https://hexdocs.pm/multibase/](https://hexdocs.pm/multibase).

First, let's audit the current version to see what kind of encodings are available:

```elixir
Multibase.encodings()
[:identity, :base1, :base2, :base8, :base10, :base16_upper, :base16_lower,
 :base32_hex_upper, :base32_hex_lower, :base32_hex_pad_upper,
 :base32_hex_pad_lower, :base32_upper, :base32_lower, :base32_pad_upper,
 :base32_pad_lower, :base32_z, :base58_flickr, :base58_btc, :base64,
 :base64_pad, :base64_url, :base64_url_pad]
```

There are 22 encodings. Each is represented by a unique `encoding_id` atom.

The `Multibase` module encapsulates the Main API. It typically provides 2 versions of most functions. The first form is the typical `{:ok, result}` and `:error` or `{:error, reason}`. The `!` suffixed functions will raise exceptions, typically if a bad `encoding_id` is passed or another error is encountered.

Encoding data using a variety of different encodings:

```elixir
# Let's consider some data to encode. We start with a simple Elixir binary.
data =  "I can be encoded many ways, but I am unique"

# We call `encode!/1` and pass an atom representing the encoding type as an ID
Multibase.encode!(data, :base16_lower)
"f492063616e20626520656e636f646564206d616e7920776179732c20627574204920616d20756e69717565"

Multibase.encode!(data, :base8)
"71111006154133420142312201453346155731062544100665413347444035660571346260403047256410044440302664403526715134272545"

 Multibase.encode!(data, :base32_hex_upper)
"V94G66OBE41H6A835DPHMUP35CGG6QOBEF4G7EOBPECM20OJLEGG4I831DKG7ARJ9E5QMA"

# We can also call a pattern matching friendly version
Multibase.encode(data, :base58_btc)       
{:ok, "z6PS9nHyn6kM1ECybTAjN4iAmtekMSSjXbisXp5xTBsmcLsRsYY85Z1Ko1vL"}

# If we pass bad data, that's handled for us too
# Let's pass an encoding that clearly does not exist
Multibase.encode(data, :all_your_bases)
{:error, :unsupported_encoding}

# Let's again do the same, but using the `!` version
Multibase.encode!(data, :all_your_bases)
# ** (ArgumentError) Unsupported encoding - no encodings for encoding id: :all_your_bases
```  

Decoding data is simple with Multibase. We can skip passing the encoding because it's already in the data, otherwise it's not Multibase binary.

```elixir
# Let's decode the data we encoded above
Multibase.decode!("f492063616e20626520656e636f646564206d616e7920776179732c20627574204920616d20756e69717565")
"I can be encoded many ways, but I am unique"

# Again we have 2 versions of the function
Multibase.decode("z6PS9nHyn6kM1ECybTAjN4iAmtekMSSjXbisXp5xTBsmcLsRsYY85Z1Ko1vL")
{:ok, "I can be encoded many ways, but I am unique"}

# Suppose we want to know what encoding was used to encode as part of the decoding process
Multibase.codec_decode!("V94G66OBE41H6A835DPHMUP35CGG6QOBEF4G7EOBPECM20OJLEGG4I831DKG7ARJ9E5QMA")
{"I can be encoded many ways, but I am unique", :base32_hex_upper}

Multibase.codec_decode("71111006154133420142312201453346155731062544100665413347444035660571346260403047256410044440302664403526715134272545")
{:ok, {"I can be encoded many ways, but I am unique", :base8}}

# error handling works as expected
Multibase.decode("~$#%@$%gibberish")            
:error

# Let's tamper with some base58 data by inserting a non-alphabet character. 
# The given decoder will bubble up that this data is no good
Multibase.decode("z6PS9nHyn6kM1ECybTAjN4iAmtekMSSjXbisXp5xTBsmcLsRsYY85Z1Ko1vLTAMPERED0")    
:error
```

Suppose we are lazy and just want to query what's available as Multibase grows, or we want to encode using several encodings. 

We can easily query the encodings list:

```elixir
Multibase.encodings_for!(:base32)
[:base32_hex_pad_upper, :base32_hex_pad_lower, :base32_upper, :base32_lower,
 :base32_pad_upper, :base32_pad_lower, :base32_z]

# and the reverse
 Multibase.encoding_family!(:base32_pad_upper)
:base32

# Or we want to know what prefix to expect, perhaps for testing, debugging, auditing, pattern matching, etc.
Multibase.prefix!(:base32_pad_lower)
"c"

Multibase.prefix(:identity)         
{:ok, <<0>>}
```

We can also prefix already encoded data. This might be useful if you want to just use Multibase as an adapter or are doing encoding out-of-band. It's much easier and safer to just encode with Multibase but nonetheless this capability is available should you need it.

```elixir
# Suppose somewhere else we do this
b58_flickr_encoded_data = B58.encode58(data, alphabet: :flickr)    
"6or9MhYM6Km1ecYAsaJn4HaLTDKmrrJwAHSwP5XsbSLBkSqSxx85y1jN1Vk"


# As long as we pick the right prefix, we should know
# As you might expect, this puts some burden on the code so we should prefer to use `encode/2` or `encode!/2`
Multibase.multibase(b58_flickr_encoded_data, :base58_flickr)
{:ok, "Z6or9MhYM6Km1ecYAsaJn4HaLTDKmrrJwAHSwP5XsbSLBkSqSxx85y1jN1Vk"}

# There's an exception raising version too
Multibase.multibase!(b58_flickr_encoded_data, :base58_flickr)
"Z6or9MhYM6Km1ecYAsaJn4HaLTDKmrrJwAHSwP5XsbSLBkSqSxx85y1jN1Vk"
```
## Installation

Multibase is available via [Hex](https://hex.pm/packages/multibase). The package can be installed by adding `basefiftyeight` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:multibase, "~> 0.0.1"}
  ]
end
```

API Documentation can be found at [https://hexdocs.pm/multibase/](https://hexdocs.pm/multibase).
