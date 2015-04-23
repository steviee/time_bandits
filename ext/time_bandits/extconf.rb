require "mkmf"

have_func("getrusage")

create_makefile("time_bandits")
