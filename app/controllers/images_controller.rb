require 'json'
#require 'exifr'
require 'rmagick'
require 'digest'
require 'zip'

class ImagesController < ApplicationController

  def index
    @images = Image.all
  end
  def new
    rawFiles = scanImages
    new = newImages(rawFiles)
    tmp = processImages(new)
    @files = tmp
    @image = Image.new
  end

  def create
    images = []

    image_params.each do |p|
      image = Image.new(p)
      images << image if image.save
    end

    render json: images, status: 201
  end

  def show
    @image = Image.find(params[:id])
  end

  def scanImages
    images = Array.new
    dirSet = Setting.where(name: "directory").first
    dirs = JSON.parse(dirSet.value)
    dirs.each do |dir|
      files = Dir[dir+"*"]
      files.each do |file|
        image = Hash.new
        image['dir'] = dir
        image['filename'] = file.split("/").last
        if image['filename'].include? ".JPG"
#          exif = nil
#          exif = EXIFR::JPEG.new(file)
#          image['model'] = exif.model
#          image['dateTaken'] = exif.date_time
#          image['thumb'] = exif.thumbnail
          images << image
        end
      end
    end
    return images
  end
  def processImages(images)
    resSet = Setting.where(name: "resolutions").first
    res = JSON.parse(resSet.value)
    images.each do |image|
      file = image['dir']+"/"+image['filename']
      image['md5'] = Digest::MD5.file(file)
      thumbnail = "./app/assets/images/thumbs/#{image['md5']}.#{image['filename'][-3,3]}"
      if !File.exist?(thumbnail)
        exif = Magick::Image.read(file)[0]
        exif.thumbnail(0.10).write(thumbnail)
        res.each do |r|
          if !File.exist?("./app/assets/images/#{r}")
            Dir.mkdir("./app/assets/images/#{r}")
          end
          resArr = r.split("x")
          #exif.resize_to_fill(resArr[0].to_i,resArr[1].to_i).write("./app/assets/images/#{r}/#{image['md5']}.#{image['filename'][-3,3]}")
          exif.change_geometry!(r){|cols,rows,img| img.resize!(cols,rows).write("./app/assets/images/#{r}/#{image['md5']}.#{image['filename'][-3,3]}")}
        end
      end
      img = Magick::ImageList.new(file)
      image['dateTaken'] = DateTime.strptime(img.get_exif_by_entry('DateTimeOriginal')[0][1], '%Y:%m:%d %H:%M:%S') 
    end
  end
  def newImages(images)
      existingImages = Image.all
      newImages = []
      sortImages = images.sort_by { |h| [h['filename'],h['dir']] }
      sortExistingImages = existingImages.order(:filename,:dir)
      x = 0
      y = 0
      while true do
        if newImages.length > 9
          break
        end
        if sortExistingImages.length > 0
          if sortImages[x]['filename'] == sortExistingImages[y].filename and sortImages[x]['dir'] == sortExistingImages[y].dir
            x += 1
            y += 1
          elsif sortImages[x]['filename'] < sortExistingImages[y].filename
            newImages << sortImages[x]
            x += 1
          elsif sortImages[x]['filename'] > sortExistingImages[y].filename
            y += 1
          elsif sortImages[x]['filename'] == sortExistingImages[y].filename and sortImages[x]['dir'] < sortExistingImages[y].dir
            newImages << sortImages[x]
            x += 1
          elsif sortImages[x]['filename'] == sortExistingImages[y].filename and sortImages[x]['dir'] > sortExistingImages[y].dir
            y += 1
          end
        end
        if y == existingImages.length and x != sortImages.length
          newImages << sortImages[x]
          x += 1
          if y > 0
            y -= 1
          end
        end

        if x == sortImages.length
          break
        end
      end
      return newImages
  end

  def retrieve
    allImages = Image.all
    randImages = allImages.sample(10)
    filename = 'photos.zip'
    temp_file = Tempfile.new(filename)
    res = params[:res]
    begin
      #Zip::OutputStream.open(temp_file) {|zos|}
      Zip::File.open(temp_file.path, Zip::File::CREATE) do |zip|
        randImages.each do |i|
          zip.add(i['filename'],"./app/assets/images/#{res}/#{i['preMd5']}.#{i['filename'][-3,3]}")
        end
      end

      zip_data = File.read(temp_file.path)
      send_data(zip_data, :type => 'application/zip', :filename => filename)
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  private
    def image_params
        params.require(:image).map { |p| p.permit(:ignore, :filename, :preMd5, :dir, :orientation, :tags, :dateTaken, :dateIsEstimate) }
    end

end
