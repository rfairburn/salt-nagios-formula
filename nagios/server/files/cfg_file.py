def run():
  output = ""
  for type,defines in context['configs'].items():
    output += "# " + type + "\n\n"
    for name,define_list in defines.items():
      output += "define " + type + " {\n"
      length = 0
      for define in define_list:
        item,value = define.items()[0]
        if len(item) >= length:
          length = len(item) + 1
      for define in define_list:
        item,value = define.items()[0]
        output += "    " + item.ljust(length) + " " + value + "\n"
      output += "}\n\n\n\n"
  return output
