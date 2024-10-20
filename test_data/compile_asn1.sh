#!/bin/bash


OUTPUT_DIR="../test/support/asn1_generated"

mkdir -p "$OUTPUT_DIR"

erlc -o "$OUTPUT_DIR" -I "$OUTPUT_DIR" +noobj -bper +maps +undec_rest TEST-ASN1.asn1