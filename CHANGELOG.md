# Changelog

## 0.2.9

Changelog starts. Public release

## 0.2.10

Improvement to documentation

## 0.2.11

Another sequence of documentation updates

## 0.2.12

Added Recursive custom type for dynamic parsing recursive datastructures

## 0.2.13

Removed decode_field/2 function.

Added compiled time use cases in exchange: 

compile_decode_only [ :field_name_a, :field_name_b ] and compile_decode_only :function_name [ :field_name_a, :field_name_b ]

## 0.2.14

Added compile time exceptions for invalid use of new feature compile_decode_only

## 0.2.15

Warning message for not compiled pattern of compile_decode_only includes module name

## 0.2.16

Added compile time exceptions for invalid use (request of non-existing field) of compile_decode_only