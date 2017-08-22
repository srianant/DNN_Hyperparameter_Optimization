# -*- coding: binary -*-

module Msf
module Exploit::FileDropper

  def initialize(info = {})
    super

    register_advanced_options(
      [
        OptInt.new('FileDropperDelay', [false, 'Delay in seconds before attempting file cleanup'])
      ], self.class)
  end

  # Record file as needing to be cleaned up
  #
  # @param files [Array<String>] List of paths on the target that should
  #   be deleted during cleanup. Each filename should be either a full
  #   path or relative to the current working directory of the session
  #   (not necessarily the same as the cwd of the server we're
  #   exploiting).
  # @return [void]
  def register_files_for_cleanup(*files)
    @dropped_files ||= []
    @dropped_files += files

    nil
  end

  # Singular version
  alias register_file_for_cleanup register_files_for_cleanup

  # When a new session is created, attempt to delete any files that the
  # exploit created.
  #
  # @param (see Msf::Exploit#on_new_session)
  # @return [void]
  def on_new_session(session)
    super

    if session.type == 'meterpreter'
      session.core.use('stdapi') unless session.ext.aliases.include?('stdapi')
    end

    unless @dropped_files && @dropped_files.length > 0
      return
    end

    @dropped_files.delete_if do |file|
      exists_before = file_dropper_file_exist?(session, file)
      if file_dropper_delete(session, file)
        file_dropper_deleted?(session, file, exists_before)
      else
        false
      end
    end
  end

  # While the exploit cleanup do a last attempt to delete any files created
  # if there is a file_rm method available. Warn the user if any files were
  # not cleaned up.
  #
  # @see Msf::Exploit#cleanup
  # @see Msf::Post::File#file_rm
  def cleanup
    super

    # Check if file_rm method is available (local exploit, mixin support, module support)
    if not @dropped_files or @dropped_files.empty?
      return
    end

    if respond_to?(:file_rm)
      delay = datastore['FileDropperDelay']
      if delay
        print_status("Waiting #{delay}s before file cleanup...")
        select(nil,nil,nil,delay)
      end

      @dropped_files.delete_if do |file|
        begin
          file_rm(file)
          # We don't know for sure if file has been deleted, so always warn about it to the user
          false
        rescue ::Exception => e
          vprint_error("Failed to delete #{file}: #{e}")
          elog("Failed to delete #{file}: #{e.class}: #{e}")
          elog("Call stack:\n#{e.backtrace.join("\n")}")
          false
        end
      end
    end

    @dropped_files.each do |f|
      print_warning("This exploit may require manual cleanup of '#{f}' on the target")
    end

  end

  private

  # See if +path+ exists on the remote system and is a regular file
  #
  # @param path [String] Remote filename to check
  # @return [Boolean] True if the file exists, otherwise false.
  def file_dropper_file_exist?(session, path)
    if session.platform =~ /win/
      normalized = file_dropper_win_file(path)
    else
      normalized = path
    end

    if session.type == 'meterpreter'
      stat = session.fs.file.stat(normalized) rescue nil
      return false unless stat
      stat.file?
    else
      if session.platform =~ /win/
        f = shell_command_token("cmd.exe /C IF exist \"#{normalized}\" ( echo true )")
        if f =~ /true/
          f = shell_command_token("cmd.exe /C IF exist \"#{normalized}\\\\\" ( echo false ) ELSE ( echo true )")
        end
      else
        f = session.shell_command_token("test -f \"#{normalized}\" && echo true")
      end

      return false if f.nil? || f.empty?
      return false unless f =~ /true/
      true
    end
  end

  # Sends a file deletion command to the remote +session+
  #
  # @param [String] file The file to delete
  # @return [Boolean] True if the delete command has been executed in the remote machine, otherwise false.
  def file_dropper_delete(session, file)
    win_file = file_dropper_win_file(file)

    if session.type == 'meterpreter'
      begin
        # Meterpreter should do this automatically as part of
        # fs.file.rm().  Until that has been implemented, remove the
        # read-only flag with a command.
        if session.platform =~ /win/
          session.shell_command_token(%Q|attrib.exe -r #{win_file}|)
        end
        session.fs.file.rm(file)
        true
      rescue ::Rex::Post::Meterpreter::RequestError
        false
      end
    else
      win_cmds = [
        %Q|attrib.exe -r "#{win_file}"|,
        %Q|del.exe /f /q "#{win_file}"|
      ]
      # We need to be platform-independent here. Since we can't be
      # certain that {#target} is accurate because exploits with
      # automatic targets frequently change it, we just go ahead and
      # run both a windows and a unix command in the same line. One
      # of them will definitely fail and the other will probably
      # succeed. Doing it this way saves us an extra round-trip.
      # Trick shared by @mihi42
      session.shell_command_token("rm -f \"#{file}\" >/dev/null ; echo ' & #{win_cmds.join(" & ")} & echo \" ' >/dev/null")
      true
    end
  end

  # Checks if a file has been deleted by the current job
  #
  # @param [String] file The file to check
  # @return [Boolean] If the file has been deleted, otherwise false.
  def file_dropper_deleted?(session, file, exists_before)
    if exists_before  && file_dropper_file_exist?(session, file)
      print_error("Unable to delete #{file}")
      false
    elsif exists_before
      print_good("Deleted #{file}")
      true
    else
      print_warning("Tried to delete #{file}, unknown result")
      true
    end
  end

  # Converts a file path to use the windows separator '\'
  #
  # @param [String] file The file path to convert
  # @return [String] The file path converted
  def file_dropper_win_file(file)
    file.gsub('/', '\\\\')
  end

end
end
