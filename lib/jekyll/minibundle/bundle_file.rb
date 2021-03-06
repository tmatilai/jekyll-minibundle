require 'jekyll/minibundle/asset_bundle'
require 'jekyll/minibundle/asset_file_operations'
require 'jekyll/minibundle/asset_stamp'
require 'jekyll/minibundle/asset_tag_markup'

module Jekyll::Minibundle
  class BundleFile
    include AssetFileOperations

    @@mtimes = {}

    def initialize(config)
      @type = config['type']
      @site_source_dir = config['site_dir']
      asset_source_dir = File.join @site_source_dir, config['source_dir']
      @assets = config['assets'].map { |asset_path| File.join asset_source_dir, "#{asset_path}.#{@type}" }
      @asset_destination_path = config['destination_path']
      @attributes = config['attributes']
    end

    def path
      asset_bundle.path
    end

    def asset_path
      "#{@asset_destination_path}-#{asset_stamp}.#{@type}"
    end

    def destination(site_destination_dir)
      File.join site_destination_dir, asset_path
    end

    def mtime
      @assets.max { |f| File.stat(f).mtime.to_i }
    end

    def modified?
      @@mtimes[path] != mtime
    end

    def write(site_destination_dir)
      is_modified = modified?

      rebundle_assets if is_modified

      if File.exists?(destination(site_destination_dir)) && !is_modified
        false
      else
        update_mtime
        write_destination site_destination_dir
        true
      end
    end

    def markup
      AssetTagMarkup.make_markup @type, asset_path, @attributes
    end

    private

    def asset_stamp
      @asset_stamp ||= AssetStamp.from_file(path)
    end

    def asset_bundle
      @asset_bundle ||= AssetBundle.new(@type, @assets, @site_source_dir).make_bundle
    end

    def rebundle_assets
      @asset_stamp = nil
      asset_bundle.make_bundle
    end

    def update_mtime
      @@mtimes[path] = mtime
    end
  end
end
