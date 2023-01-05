#!/bin/sh
ocamlfind opt -linkpkg -package unix -o birthdays birthdays.ml && time ./birthdays
