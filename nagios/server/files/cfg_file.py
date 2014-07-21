def run():
  output = ""
  for type,defines in context['configs'].items():
    output += "# " + type + "\n\n"
    for name,define in defines.items():
      output += "define " + type + " {\n"
      length = 0
      for item,value in define.items():
        if len(item) >= length:
          length = len(item) + 1
      for item,value in define.items():
        output += "    " + item.ljust(length) + " " + value + "\n"
      output += "}\n\n"
  return output
