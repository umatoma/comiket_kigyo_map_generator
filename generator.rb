require 'optparse'
require 'csv'
require 'RMagick'
include Magick

option = {}

OptionParser.new do |opt|
  opt.on('--comiket_id=VALUE', 'コミケID') { |v| option[:comiket_id] = v }
  opt.parse!(ARGV)
end

p option

COMIKET_ID = option[:comiket_id]
KIGYOS_CSV_FILE_NAME = "comiket_#{COMIKET_ID}.csv"
EXPORT_CSV_FILE_NAME = "export_comiket_#{COMIKET_ID}.csv"
FONT_PATH = '/Library/Fonts/ヒラギノ丸ゴ Pro W4.otf'

IMAGE_BACKGROUND_COLOR = 'white'
IMAGE_FILE_NAME = "comiket_#{COMIKET_ID}.png"
IMAGE_MARGIN = 30

BOOTH_WIDTH = 36
BOOTH_HEIGHT = 18
BOOTH_FILL = 'white'
BOOTH_STROKE = 'black'
BOOTH_STROKE_WIDTH = 1

SPACE_NO_POINT_SIZE = 12

kigyos = CSV.table(KIGYOS_CSV_FILE_NAME)

image_w = (kigyos.map { |x| x[:x] }.max + 1) * BOOTH_WIDTH + BOOTH_STROKE_WIDTH
image_h = (kigyos.map { |x| x[:y] }.max + 1) * BOOTH_HEIGHT + BOOTH_STROKE_WIDTH
image = Image.new(image_w, image_h)

image_back_w = image_w + IMAGE_MARGIN * 2
image_back_h = image_h + IMAGE_MARGIN * 2
image_back = Image.new(image_back_w, image_back_h) {
  self.background_color = IMAGE_BACKGROUND_COLOR
}

booths_gc = Draw.new
booths_gc.fill(BOOTH_FILL)
booths_gc.stroke(BOOTH_STROKE)
booths_gc.stroke_width(BOOTH_STROKE_WIDTH)

kigyo_no_gc = Draw.new
kigyo_no_gc.pointsize(SPACE_NO_POINT_SIZE)
kigyo_no_gc.pointsize = SPACE_NO_POINT_SIZE
kigyo_no_gc.font(FONT_PATH)
kigyo_no_gc.font = FONT_PATH

## Export map data
csv_str = CSV.generate do |csv|
  csv << %w(kigyo_no map_pos_x map_pos_y)

  kigyos.each do |kigyo|
    ## Draw booth frame
    x1 = kigyo[:x] * BOOTH_WIDTH
    y1 = kigyo[:y] * BOOTH_HEIGHT
    x2 = x1 + BOOTH_WIDTH * kigyo[:w]
    y2 = y1 + BOOTH_HEIGHT * kigyo[:h]
    booths_gc.rectangle(x1, y1, x2, y2)

    ## Draw booth space number
    kigyo_no = kigyo[:kigyo_no].to_s
    metrics = kigyo_no_gc.get_type_metrics(kigyo_no)
    x = x1 + (x2 - x1 - metrics.width) * 0.5
    y = y2 - (y2 - y1 - SPACE_NO_POINT_SIZE) * 0.5
    kigyo_no_gc.text(x, y, kigyo_no)

    csv << [
      kigyo[:kigyo_no],
      IMAGE_MARGIN + x1,
      IMAGE_MARGIN + y1
    ]
  end
end

booths_gc.draw(image)
kigyo_no_gc.draw(image)

image_back.composite!(image, CenterGravity, OverCompositeOp)
image_back.write(IMAGE_FILE_NAME)

File.write(EXPORT_CSV_FILE_NAME, csv_str)
