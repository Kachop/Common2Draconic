package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:unicode/utf8"
import rl "vendor:raylib"

CWD: string

TICK: rune
CROSS: rune

when ODIN_OS == .Windows {
  PATH_SEPERATOR := "\\"
} else when ODIN_OS == .Linux {
  PATH_SEPERATOR := "/"
}

INPUT: string
OUTPUT: string

FONT_SIZE: i32

SYMBOLS_PATH: string
SYMBOLS: map[rune]rl.Image

BACKGROUND: rl.Color
NO_BACKGROUND: bool

HELP: bool

scale_factor: f32

width : i32 : 1920
height : i32 = 1080

x_padding: f32
y_padding: f32

draw_width: f32
draw_height: f32

@(init)
init :: proc() {
  rl.SetTraceLogLevel(.NONE)
  TICK, _ = utf8.decode_rune_in_bytes([]byte{0xE2, 0x9C, 0x93})
  CROSS, _ = utf8.decode_rune_in_bytes([]byte{0xE2, 0x9D, 0x8C})

  CWD = os.get_current_directory()

  INPUT = fmt.tprint(CWD, "input.txt", sep=PATH_SEPERATOR)
  OUTPUT = "output.txt"

  FONT_SIZE = 10

  SYMBOLS_PATH = fmt.tprint(#directory, "Symbols", sep="")
  
  parse_args(os.args)

  if HELP {return}

  scale_factor = cast(f32)FONT_SIZE / 10

  x_padding = 20 * scale_factor
  y_padding = 20 * scale_factor

  draw_width = cast(f32)width - (x_padding * 2)
  draw_height = cast(f32)height - (y_padding * 2)

  dir_handle, ok := os.open(SYMBOLS_PATH)
  defer os.close(dir_handle)

  if ok == os.ERROR_NONE {
    file_infos, err := os.read_dir(dir_handle, 0, context.temp_allocator)
    defer 
    
    if err == os.ERROR_NONE {
      fmt.printfln("%v Reading symbols in: %v", TICK, SYMBOLS_PATH)
      for file in file_infos {
        if !file.is_dir {
          if strings.split(file.name, ".")[1] == "png" {
            SYMBOLS[rune(utf8.string_to_runes(strings.split(file.name, ".")[0])[0])] = rl.LoadImage(fmt.ctprint(file.fullpath))
          }
        }
      }
    } else {
      fmt.println(CROSS, "Failed to read files in:", SYMBOLS_PATH)
    }
  } else {
    fmt.println(CROSS, "Failed to open folder:", SYMBOLS_PATH)
  }
  fmt.printfln("%v Loaded %v symbols successfully...", TICK, len(SYMBOLS))

  BACKGROUND = rl.ColorAlpha(rl.WHITE, 0) if NO_BACKGROUND else rl.ColorAlpha(rl.WHITE, 1)
}

main :: proc() {
  if HELP {return}
  to_translate_data, ok := os.read_entire_file(INPUT)
  to_translate_string := transmute(string)to_translate_data
  
  if ok {
    fmt.printfln("%v Loading common text from: %v", TICK, INPUT)
  } else {
    fmt.println(CROSS, "Cannot find file:", INPUT)
  }
  
  canvas := rl.GenImageColor(width, height, BACKGROUND)

  line_height: f32
  max_width: f32

  space_width : f32 = 100 * scale_factor
  line_padding : f32 = line_height + (20 * scale_factor)

  cursor_x : f32 = x_padding
  cursor_y : f32 = y_padding
  start_x := cursor_x

  for _, &symbol in SYMBOLS {
    rl.ImageResize(&symbol, cast(i32)(cast(f32)symbol.width * scale_factor), cast(i32)(cast(f32)symbol.height * scale_factor))
  }

  for word in strings.split(strings.to_upper(to_translate_string), " ") {
    word_width : i32 = 0
    for char in word {
      word_width += SYMBOLS[rune(char)].width
    }
    if cursor_x + cast(f32)word_width - x_padding > draw_width {
      newline(&cursor_x, &cursor_y, start_x, line_padding)
    }

    for char in word {
      switch rune(char) {
      case '\n': newline(&cursor_x, &cursor_y, start_x, line_padding)
      case 'A'..='Z', '1'..='9', '!':
        symbol := SYMBOLS[rune(char)]

        if cast(f32)symbol.height > line_height {
          line_height = cast(f32)symbol.height
          line_padding = line_height + (20 * scale_factor)
        }

        if cursor_x + cast(f32)symbol.width - x_padding > draw_width {
          newline(&cursor_x, &cursor_y, start_x, line_padding)
        }
        if cursor_y + cast(f32)symbol.height - y_padding > draw_height {
          extend_canvas(&canvas)
        }
        rl.ImageDraw(&canvas, symbol, {0, 0, cast(f32)symbol.width, cast(f32)symbol.height}, {cursor_x, cursor_y, cast(f32)symbol.width, cast(f32)symbol.height}, rl.WHITE)
        cursor_x += cast(f32)symbol.width
      }
      if cursor_x > max_width {
        max_width = cursor_x
      }
      if cursor_y > draw_height {
        extend_canvas(&canvas)
      }
    }
    if cursor_x + space_width - x_padding < draw_width {
      cursor_x += space_width
    } else {
      newline(&cursor_x, &cursor_y, start_x, line_padding)
    }

  }
  
  rl.ImageCrop(&canvas, {0, 0, cast(f32)max_width, cast(f32)cursor_y})

  if rl.ExportImage(canvas, fmt.ctprint(OUTPUT)) {
    fmt.printfln("%v Translation complete! Output: %v", TICK, OUTPUT)
  } else {
    fmt.println(CROSS, "Failed to export image to:", OUTPUT)
  }

  for k, v in SYMBOLS {
    rl.UnloadImage(v)
  }
  delete(SYMBOLS)
}

parse_args :: proc(args: []string) #no_bounds_check {
  set_input_path: bool
  set_output_path: bool
  set_font_size: bool
  set_symbols_path: bool

  args_loop: for arg, i in args {
    switch arg {
    case "-i", "-input": set_input_path = true
    case "-o", "-output": set_output_path = true
    case "-fs", "-font_size": set_font_size = true
    case "-s": set_symbols_path = true
    case "-no_background": NO_BACKGROUND = true; fmt.printfln("%v Removing background...", TICK)
    case "-help":
      fmt.printfln(
        "A tool for translating text from common to draconic!\nCurrent image formats supported:\n\t.png\n\nUsage:\n\tdraconic [arguments]\n\nArguments:\n\t-i\tThe path for the input text file.\n\t-o\tThe path for the output image.\n\t-s\tThe path to find the symbols for the translation.\n\tno_background\tFlag to set image generation to a transparant background.\n\nIf no arguments are supplied the default directories/paths are:\n\t-i\t'%v'\n\t-o\t'%v'\n\t-s\t'%v'\n",
      INPUT, fmt.tprint(CWD, OUTPUT, sep=PATH_SEPERATOR), SYMBOLS_PATH)
      HELP = true
      break args_loop
    }

    if set_input_path {
      INPUT = args[i+1]
      set_input_path = false
    }
    if set_output_path {
      OUTPUT = args[i+1]
      set_output_path = false
    }
    if set_font_size {
      size_val, _ := strconv.parse_int(args[i+1], base=10)
      fmt.println("Got size val", size_val)
      if size_val > 10 {
        FONT_SIZE = 10
      } else if size_val <= 0 {
        FONT_SIZE = 1
      } else {
        FONT_SIZE = cast(i32)size_val
      }
      set_font_size = false
    }
    if set_symbols_path {
      SYMBOLS_PATH = args[i+1]
      set_symbols_path = false
    }
  }

  if (len(strings.split(INPUT, ".")) == 1) {
    INPUT = fmt.tprintf("%v%v%v.txt", CWD, PATH_SEPERATOR, INPUT)
  }
  if (len(strings.split(OUTPUT, ".")) == 1) || (strings.split(OUTPUT, ".")[1] != ".png") {
    OUTPUT = fmt.tprintf("%v.png", strings.split(OUTPUT, ".")[0])
  }
}

newline :: proc(cursor_x: ^f32, cursor_y: ^f32, x_reset: f32, y_increment: f32) {
  cursor_x^ = x_reset
  cursor_y^ += y_increment
}

extend_canvas :: proc(canvas: ^rl.Image) {
  height *= 2
  draw_height = cast(f32)height - (y_padding * 2)
  old_canvas := canvas^
  canvas^ = rl.GenImageColor(width, height, BACKGROUND)
  rl.ImageDraw(canvas, old_canvas, {0, 0, cast(f32)width, cast(f32)height / 2}, {0, 0, cast(f32)width, cast(f32)height / 2}, rl.WHITE)
}
