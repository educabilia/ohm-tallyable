
ohm-tallyable
=============

A tally plugin for Ohm


Setup
-----

1. Include the `Tallyable` module in your model:

		include Ohm::Tallyable

2. Add a tally to your model with the following line:

		tally :category

You will need to resave every model if they already exist.

Usage
-----

To query the tallies, use the `leaderboard` class method.

    Post.leaderboard(:category)


Advanced Usage
--------------

You can also partition the tally by a certain attribute:

    tally :category, :by => :site_id

You will need to provide a value for this attribute every time you check the
leaderboard:

	Post.leaderboard(:category, :site_id => 'ar') 


Acknowledgements
----------------

Many thanks to Damian Janowski (https://github.com/djanowski) who took care to
explain me the details of coding an Ohm plugin and providing many ideas on
how to handle certain cases.
