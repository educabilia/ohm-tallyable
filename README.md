ohm-tallyable
=============

[![Gem Version](https://badge.fury.io/rb/ohm-tallyable.png)](http://badge.fury.io/rb/ohm-tallyable)
[![Code Climate](https://codeclimate.com/github/educabilia/ohm-tallyable.png)](https://codeclimate.com/github/educabilia/ohm-tallyable)

A tally plugin for Ohm that keeps counts of records for every value of an attribute


Setup
-----

1. Include the `Callbacks` and `Tallyable` modules in your model:

		include Ohm::Callbacks 
		include Ohm::Tallyable

2. Add a tally to your model with the following line:

		tally :category

You will need to resave every model if they already exist.

Usage
-----

To query the tallies, use the `leaderboard` class method.

    >> Post.leaderboard(:category)
    => [["Personal", 2], ["Work", 1]]


Advanced Usage
--------------

You can also partition the tally by a certain attribute:

    tally :category, :by => :site_id

You will need to provide a value for this attribute every time you check the
leaderboard:

	Post.leaderboard(:category, :site_id => 'ar') 


If for any reason you find yourself having to recompute the tallies, you can do
so with this line of code:

    Post.retally(:category)


Requirements
------------

This plugin works with Ohm versions higher than 0.1.3.


Acknowledgements
----------------

Many thanks to Damian Janowski (https://github.com/djanowski) who took care to
explain me the details of coding an Ohm plugin and providing many ideas on
how to handle certain cases.
