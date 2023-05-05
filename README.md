# Helper Methods

The starting point of this project is where we left the ad2-getting-started project at the end of class on Day 1.

## Setup

```
bin/setup
```

## Write some tests

We're going to be learning a _lot_ of ways to improve our code, while holding functionality constant.

That means we're going to need to do a lot of testing to make sure we didn't break functionality as we evolve our code. Once you get tired of manually clicking through every link, form, etc, consider writing some automated tests to save yourself the trouble.

Read Sections 1, 2, 4, 5, 6, and 7 of the [Rails Guide on Testing](https://guides.rubyonrails.org/testing.html). These are the kinds of tests that we write most frequently.

In this project, we have one fully functional web resource, `movies`. Create a test file, `test/system/movie_test.rb`, and take a stab at writing some System tests in it to lock down the current functionality of the application. For example, try adding a test that checks to make sure the URL `/movies` has an `<h1>` on it containing the copy "List of all movies". Run your tests with:

```
rails test test/system/movie_test.rb
```

After you’ve spent 20-30 minutes on it, you’re allowed to look at the example specs in `test/system/example_specs.rb`. You can copy-paste some or all of them into your own test file and run then periodically as you’re doing the rest of the project to ensure you didn’t break anything as we refactor.

## Walkthrough Video

There's a walkthrough video to go along with this project on Canvas.

### Clean-ups that we already know how to do

 - Anywhere you see the old `Hash` syntax (`:symbol` keys with hash rockets `=>`): switch to [the new `Hash` syntax](https://chapters.firstdraft.com/chapters/787#new-hash-syntax).
 - Anywhere you see [optional curly braces around `Hash` arguments](https://chapters.firstdraft.com/chapters/787#curly-braces-around-hash-arguments): remove them.
 - Where possible, drop `render` statements.
 - When providing keys to `params`, use `Symbol`s. (Unlike with most hashes, you can use `String`s and `Symbol`s interchangeably as keys to `params`.)

### Refactor routes

 - Re-write routes using more succinct forms of `get`, `post`, `patch`, `delete`, and, ultimately, `resources`.

### First new helper methods

 - Replace all references to URLs outside of `config/routes.rb` with route helper methods.
 - Replace all `<a>` elements in view templates with `link_to` methods.

### Forms in general

 - Replace all `<form>` elements in view templates with `form_with` methods.
 - Replace all `<input>` elements with `text_field_tag`, `number_field_tag`, `text_area_tag`, etc.
 
### Forms specifically for model objects

 - Change the names of inputs so that values in the `params` hash are nested within an inner hash.
 - Assign all of the values at once using ActiveRecord's mass assignment ability via `new` or `update`.
 - Whitelist which attributes you want to allow to be mass assigned from `params` with `params.require(:movie).permit(:title, :description)`.
 - Switch from `form_with(url:)` to `form_with(model:)`
 - Switch from `text_field_tag`, etc; to `form.text_field`, etc.
 - Move form to partial and re-use wherever possible.
