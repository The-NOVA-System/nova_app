#!/usr/grte/v4/bin/python2.7

# Copyright 2016 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Utility to convert binary data into a C/C++ array.

Usage: %s --input=input_file.bin [--output_source=output_source.cc]
          [--output_header=output_header.h] [--cpp_namespace=namespace]
          [--header_guard=HEADER_GUARD_TEXT] [--array=array_c_identifier]
          [--array_size=array_size_c_identifier] [--filename=override_filename]
          [--filename_identifier=filename_c_identifier]

By default, the output source file will be named the same as the input file,
but with .cc as the extension; the output header file will be named the
same as the input file but with .h as the extension.

By default, the data will be in an array named $NAME_data and the size will
be in a constant named $NAME_length, and the filename will be stored in
$NAME_filename. In all these cases, $NAME is the input filename (sans path and
extension) with runs of non-alphanumeric characters changed to underscores. The
header guard will be generated from the output header filename in a similar way.

By default, the data will be placed in the root namespace. If the data is placed
in the root namespace, it will be declared as a C array (using extern "C" if
compiled in C++ mode).

The actual size of $NAME_data is $NAME_length + 1, where it contains an extra
0x00 at the end. When data is actually text, $NAME_data can be used as a valid C
string directly.
"""

from os import path
from re import sub
from absl import app
from absl import flags
from absl import logging

FLAGS = flags.FLAGS

flags.DEFINE_string("input", None, "Input file containing binary data to embed")
flags.DEFINE_string("output_source", None,
                    "Output source file, defining the array data.")
flags.DEFINE_string("output_header", None,
                    "Output header file, declaring the array data.")
flags.DEFINE_string("array", None, "Identifier for the array.")
flags.DEFINE_string("array_size", None, "Identifier for the array size.")
flags.DEFINE_string("filename", None, "Override file name in code.")
flags.DEFINE_string("filename_identifier", None, "Where to put the filename.")
flags.DEFINE_string("header_guard", None,
                    "Header guard to #define in the output header.")
flags.DEFINE_string("cpp_namespace", None,
                    "C++ namespace to use. If blank, will generate a C array.")

# How many hex bytes to display in a line. Each "0x00, " takes 6 characters, so
# a width of 12 lets us fit within 80 characters.
WIDTH = 12


class Error(Exception):
  """Exception raised by methods in this module."""
  pass


def header(header_guard, namespaces, array_name, array_size_name, fileid):
  """Return a C/C++ header for the given array.

  Args:
    header_guard: Name of the HEADER_GUARD to define.
    namespaces: List of namespaces, outer to inner.
    array_name: Name of the array.
    array_size_name: Name of the array size constant.
    fileid: Name of the identifier containing the file name.

  Returns:
    A list of strings containing the C/C++ header file, line-by-line.
  """

  data = []
  data.extend([
      "// Copyright 2016 Google Inc. All Rights Reserved.",
      "",
      "#ifndef %s" % header_guard,
      "#define %s" % header_guard,
      "",
      "#include <stdlib.h>",
      ""
  ])
  if namespaces:
    data.extend([
        "namespace %s {" % ns for ns in namespaces
    ])
  else:
    data.extend([
        "#if defined(__cplusplus)",
        "extern \"C\" {",
        "#endif  // defined(__cplusplus)"])

  data.extend([
      "",
      "extern const size_t %s;" % array_size_name,
      "extern const unsigned char %s[];" % array_name,
      "extern const char %s[];" % fileid,
  ])

  data.extend([
      ""
  ])
  if namespaces:
    data.extend([
        "}  // namespace %s" % ns for ns in namespaces
    ][::-1])  # close namespaces in reverse order
  else:
    data.extend([
        "#if defined(__cplusplus)",
        "}  // extern \"C\"",
        "#endif  // defined(__cplusplus)"
    ])
  data.extend([
      "",
      "#endif  // %s" % header_guard,
      ""
  ])
  return data


def source(namespaces, array_name, array_size_name, fileid, filename,
           input_bytes):
  """Return a C/C++ source file for the given array.

  Args:
    namespaces: List of namespaces, outer to inner.
    array_name: Name of the array.
    array_size_name: Name of the array size constant.
    fileid: Name of the identifier containing the filename.
    filename: The original data filename itself.
    input_bytes: Binary data to put into the array.

  Returns:
    A string containing the C/C++ source file.
  """
  data = []
  data.extend([
      "// Copyright 2016 Google Inc. All Rights Reserved.",
      "",
      "#include <stdlib.h>",
      ""
  ])
  if namespaces:
    data.extend([
        "namespace %s {" % ns for ns in namespaces
    ])
  else:
    data.extend([
        "#if defined(__cplusplus)",
        "extern \"C\" {",
        "#endif  // defined(__cplusplus)"])

  data.extend([
      "",
      "extern const size_t %s;" % array_size_name,
      "extern const char %s[];" % fileid,
      "extern const unsigned char %s[];" % array_name, "",
      "const unsigned char %s[] = {" % array_name
  ])
  length = len(input_bytes)
  line = ""
  for idx in range(0, length):
    if idx % WIDTH == 0:
      line += "  "
    else:
      line += " "
    line += "0x%02x," % input_bytes[idx]
    if idx % WIDTH == WIDTH - 1:
      data.append(line)
      line = ""
  data.append(line)
  data.append("  0x00  // Extra \\0 to make it a C string")

  data.extend([
      "};",
      "",
      "const size_t %s =" % array_size_name,
      "  sizeof(%s) - 1;" % array_name,
      "",
      "const char %s[] =" % fileid,
      "  \"%s\";" % filename,
      "",
  ])

  if namespaces:
    data.extend([
        "}  // namespace %s" % ns for ns in namespaces
    ][::-1])  # close namespaces in reverse order
  else:
    data.extend([
        "#if defined(__cplusplus)",
        "}  // extern \"C\"",
        "#endif  // defined(__cplusplus)"
    ])
  data.extend([
      ""
  ])
  return data


def main(unused_argv):
  """Read an binary input file and output to a C/C++ source file as an array.

  Raises:
    Error: If an input file is not specified.
  """

  input_file = FLAGS.input
  if not input_file:
    raise Error("No input file specified.")
  input_file_base = FLAGS.input.rsplit(".", 1)[0]

  output_source = FLAGS.output_source
  if not output_source:
    output_source = input_file_base + ".cc"
    logging.debug("Using default --output_source='%s'", output_source)

  output_header = FLAGS.output_header
  if not output_header:
    output_header = input_file_base + ".h"
    logging.debug("Using default --output_header='%s'", output_header)

  identifier_base = sub("[^0-9a-zA-Z]+", "_", path.basename(input_file_base))
  array_name = FLAGS.array
  if not array_name:
    array_name = identifier_base + "_data"
    logging.debug("Using default --array='%s'", array_name)

  array_size_name = FLAGS.array_size
  if not array_size_name:
    array_size_name = identifier_base + "_size"
    logging.debug("Using default --array_size='%s'", array_size_name)

  fileid = FLAGS.filename_identifier
  if not fileid:
    fileid = identifier_base + "_filename"
    logging.debug("Using default --filename_identifier='%s'", fileid)

  filename = FLAGS.filename
  if filename is None:  # but not if it's the empty string
    filename = path.basename(input_file)
    logging.debug("Using default --filename='%s'", filename)

  header_guard = FLAGS.header_guard
  if not header_guard:
    header_guard = sub("[^0-9a-zA-Z]+", "_", "_" + output_header).upper()
    logging.debug("Using default --header_guard='%s'", header_guard)

  namespace = FLAGS.cpp_namespace
  namespaces = namespace.split("::") if namespace else []

  with open(input_file, "rb") as infile:
    input_bytes = bytearray(infile.read())
    logging.debug("Read %d bytes from %s", len(input_bytes), input_file)

  header_text = "\n".join(header(header_guard, namespaces, array_name,
                                 array_size_name, fileid))
  source_text = "\n".join(source(namespaces, array_name, array_size_name,
                                 fileid, filename, input_bytes))

  with open(output_header, "w") as hdr:
    hdr.write(header_text)
    logging.debug("Wrote header file %s", output_header)

  with open(output_source, "w") as src:
    src.write(source_text)
    logging.debug("Wrote source file %s", output_source)

if __name__ == "__main__":
  app.run(main)
