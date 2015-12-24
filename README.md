# Callipers
A Glyphs.app plugin for visualising stroke uniformity.

The Callipers plugin helps you to visualize the thickness of strokes. If you are creating a low contrast font, you want to ensure that curves on the inside and outside of a stroke vary at the same rate, so that your stroke remains a consistent stem thickness throughout the curve. Presumably decent type designers can do this by eye, but I am not a decent type designer, and need help from a computer to tell me whether my stems have consistent thickness or not. That's what the Callipers plugin does. This animation should be worth a thousand words:

![Animation](https://raw.githubusercontent.com/simoncozens/Callipers/master/callipers.gif)

First, select the Callipers tool from the tool bar. Then draw a line through the stem; this green line marks where the measurement will start. Then draw another line; the red one marks where it will stop. (If you don't bisect exactly two curves, you have to do it again.) Then Callipers will show you your stem thickness: green marks areas of average thickness; redder areas are thicker than average and bluer ones are thinner than average.
