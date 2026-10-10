Efficient Pure Ruby Unicode Normalization (eprun)
===

(pronounced ee-prune)

## Introduction

This library was originally developed by Martin J. Dürst and Ayumu Nojima, a professor and graduate student at Aoyama Gakuin university in Japan. In 2013, Dürst presented eprun, a fast and efficient pure-ruby Unicode normalization algorithm, at the [International Unicode Conference 37](https://www.unicodeconference.org/iuc37/Conference-Program.pdf) in Santa Clara, California. A textual version of the presentation can be found [here](http://www.sw.it.aoyama.ac.jp/2013/pub/RubyNorm/).

Shorty after @camertron met Dürst at the conference, @camertron packaged up eprun into a Rubygem, published it to rubygems.org, and replaced the original normalization algorithm in [TwitterCLDR](https://github.com/ruby-i18n/twitter-cldr-rb) with eprun.

Dürst, an active member of the Ruby community back in those days, was eventually able to upstream a version of eprun into Ruby itself. The `String#unicode_normalize` method uses a modified version of eprun to perform normalization work.

## Purpose

The version of eprun built into Ruby only supports a single version of the Unicode Character Database (UCD), which evolves over time. TwitterCLDR uses a specific version of the UCD, and needs eprun to use the same one for consistency and compatibility. Other libraries dependent on eprun may also have the same need. For this reason, eprun supports the last 5 UCD versions.

## Usage

First, require the library:

```ruby
require "eprun"
```

### Normalizing

Eprun's normalization API consists of two methods. To normalize a string:

```ruby
Eprun.normalize("abc")
```

`Eprun.normalize` accepts the normalization form as the second argument. The valid normalization forms are `:nfc` (the default), `:nfd`, `:nfkc`, and `:nfkd`. For more information on Unicode normalization forms, see the [Unicode Standard Annex #15](https://www.unicode.org/reports/tr15/).

### Checking normalization

The second API method tests if a string is already normalized:

```ruby
Eprun.normalized?("abc")
```

## Using Different UCD Versions

The currently supported UCD versions can be inspected via the `Eprun::UCD_VERSIONS` constant, which is an array of strings of the form "1.2.3."

To change the version eprun will use during normalization operations, set `Eprun.current_version`.

```ruby
Eprun.current_version = "17.0.0"

# normalizes using UCD v17
Eprun.normalize("abc")
```

There's also a `.with_version` method that changes the current version for the duration of the given block:

```ruby
Eprun.with_version("17.0.0") do
  # normalizes using UCD v17
  Eprun.normalize("abc")
end
```

## Running Tests

Run tests by executing:

```shell
bundle exec rake
```

## Re-generating Normalization Data

To download the necessary Unicode files, first run:

```shell
bundle exec rake update_data
```

Then, to re-generate the normalization tables, regexes, etc, run:

```shell
bundle exec rake generate_tables
```

## License

Licensed under the terms of the original eprun library, which is licensed under the same terms as Ruby.
