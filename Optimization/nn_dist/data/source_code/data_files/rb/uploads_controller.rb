class UploadsController < ApplicationController
  before_filter :ensure_logged_in, except: [:show]
  skip_before_filter :preload_json, :check_xhr, :redirect_to_login_if_required, only: [:show]

  def create
    type = params.require(:type)
    file = params[:file] || params[:files].try(:first)
    url = params[:url]
    client_id = params[:client_id]
    synchronous = (current_user.staff? || is_api?) && params[:synchronous]

    if type == "avatar"
      if SiteSetting.sso_overrides_avatar || !SiteSetting.allow_uploaded_avatars
        return render json: failed_json, status: 422
      end
    end

    if synchronous
      data = create_upload(type, file, url)
      render json: data.as_json
    else
      Scheduler::Defer.later("Create Upload") do
        data = create_upload(type, file, url)
        MessageBus.publish("/uploads/#{type}", data.as_json, client_ids: [client_id])
      end
      render json: success_json
    end
  end

  def show
    return render_404 if !RailsMultisite::ConnectionManagement.has_db?(params[:site])

    RailsMultisite::ConnectionManagement.with_connection(params[:site]) do |db|
      return render_404 unless Discourse.store.internal?
      return render_404 if SiteSetting.prevent_anons_from_downloading_files && current_user.nil?
      return render_404 if SiteSetting.login_required? && db == "default" && current_user.nil?

      if upload = Upload.find_by(sha1: params[:sha]) || Upload.find_by(id: params[:id], url: request.env["PATH_INFO"])
        opts = { filename: upload.original_filename }
        opts[:disposition] = 'inline' if params[:inline]
        send_file(Discourse.store.path_for(upload), opts)
      else
        render_404
      end
    end
  end

  protected

  def render_404
    render nothing: true, status: 404
  end

  def create_upload(type, file, url)
    begin
      maximum_upload_size = [SiteSetting.max_image_size_kb, SiteSetting.max_attachment_size_kb].max.kilobytes

      # ensure we have a file
      if file.nil?
        # API can provide a URL
        if url.present? && is_api?
          tempfile = FileHelper.download(url, maximum_upload_size, "discourse-upload-#{type}") rescue nil
          filename = File.basename(URI.parse(url).path)
        end
      else
        tempfile = file.tempfile
        filename = file.original_filename
        content_type = file.content_type
      end

      return { errors: I18n.t("upload.file_missing") } if tempfile.nil?

      # convert pasted images to HQ jpegs
      if filename == "blob.png" && SiteSetting.convert_pasted_images_to_hq_jpg
        jpeg_path = "#{File.dirname(tempfile.path)}/blob.jpg"
        `convert #{tempfile.path} -quality #{SiteSetting.convert_pasted_images_quality} #{jpeg_path}`
        # only change the format of the image when JPG is at least 5% smaller
        if File.size(jpeg_path) < File.size(tempfile.path) * 0.95
          filename = "blob.jpg"
          content_type = "image/jpeg"
          tempfile = File.open(jpeg_path)
        else
          File.delete(jpeg_path) rescue nil
        end
      end

      # allow users to upload large images that will be automatically reduced to allowed size
      max_image_size_kb = SiteSetting.max_image_size_kb.kilobytes
      if max_image_size_kb > 0 && FileHelper.is_image?(filename)
        if File.size(tempfile.path) >= max_image_size_kb && Upload.should_optimize?(tempfile.path)
          attempt = 2
          allow_animation = type == "avatar" ? SiteSetting.allow_animated_avatars : SiteSetting.allow_animated_thumbnails
          while attempt > 0
            downsized_size = File.size(tempfile.path)
            break if downsized_size < max_image_size_kb
            image_info = FastImage.new(tempfile.path) rescue nil
            w, h = *(image_info.try(:size) || [0, 0])
            break if w == 0 || h == 0
            downsize_ratio = best_downsize_ratio(downsized_size, max_image_size_kb)
            dimensions = "#{(w * downsize_ratio).floor}x#{(h * downsize_ratio).floor}"
            OptimizedImage.downsize(tempfile.path, tempfile.path, dimensions, filename: filename, allow_animation: allow_animation)
            attempt -= 1
          end
        end
      end

      upload = Upload.create_for(current_user.id, tempfile, filename, File.size(tempfile.path), content_type: content_type, image_type: type)

      if upload.errors.empty? && current_user.admin?
        retain_hours = params[:retain_hours].to_i
        upload.update_columns(retain_hours: retain_hours) if retain_hours > 0
      end

      if upload.errors.empty? && FileHelper.is_image?(filename)
        Jobs.enqueue(:create_thumbnails, upload_id: upload.id, type: type, user_id: params[:user_id])
      end

      upload.errors.empty? ? upload : { errors: upload.errors.values.flatten }
    ensure
      tempfile.try(:close!) rescue nil
    end
  end

  def best_downsize_ratio(downsized_size, max_image_size)
    if downsized_size / 9 > max_image_size
      0.3
    elsif downsized_size / 3 > max_image_size
      0.6
    else
      0.8
    end
  end

end
