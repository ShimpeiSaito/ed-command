class Ed
  # TODO: 全体的なリファクタリング
  def initialize()
    @file = ARGV[0]
    @input = ''
    @cmd_flg = true
    @address = ''
    @command = ''
    @parameter = ''
    @quit = false
    @current = 1

    begin
      File.open(@file) do |f|
        @buffer = f.readlines
      end
      # @buffer = ARGF.readlines
    rescue StandardError
      p '今はファイル指定して？'
    end

    loop do
      _read
      _eval
      _print
    end
  end

  def _read
    @input = $stdin.gets.chomp
    OptionParser.new do |op|
      op.on('-l') { |b| @lines_flg = true }
      op.on('-w') { |b| @words_flg = true }
      op.on('-c') { |b| @bytes_flg = true }
      @no_opt_flg = true if ARGV.length == op.parse!(ARGV).length
    end
  end

  def _eval
    addr = '(?:\d+|[.$,;]|\/.*\/)'
    cmnd = '(?:wq|[acdfijnpqrw=]|\z)'
    prmt = '(?:.*)'
    # TODO: それぞれを取得する方法がわからん。parsar使う？
    if @input =~ /\A(#{addr}(,#{addr})?)?(#{cmnd})(#{prmt})?\z/
      @address =    @input.slice(/(#{addr}(,#{addr})?)?/)
      @command =    @input.slice(/(#{cmnd})/)
      @parameter =  @input.slice(/(#{prmt})?/)
    else
      @cmd_flg = false
      return
    end

    case @command
    when 'q'
      unless @address == '' || @parameter == ''
        @cmd_flg = false
        return
      end
      exit
    when 'p', 'n'
      if @address.split(',')[0].to_i.zero?
        @cmd_flg = false
        return
      end
      if @address.split(',').length == 1
        if @command == 'n'
          puts "#{@address.split(',')[0].to_i}    #{@buffer[@address.split(',')[0].to_i - 1]}"
        else
          puts @buffer[@address.split(',')[0].to_i - 1]
        end
      else
        (@address.split(',')[0].to_i - 1..@address.split(',')[1].to_i - 1).each do |i|
          if @command == 'n'
            puts "#{i}    #{@buffer[i]}"
          else
            puts @buffer[i]
          end
        end
      end
    when 'd'
      if @address.split(',')[0].to_i.zero?
        @cmd_flg = false
        return
      end
      if @address.split(',').length == 1
        @buffer.delete(@address.split(',')[0].to_i - 1)
      end
      (@address.split(',')[0].to_i - 1..@address.split(',')[1].to_i - 1).each do |i|
        @buffer.delete(i)
      end
      # TODO: @bufferをファイルに書き込む
    when ''
      if @address.split(',').length == 1
        @current = @address.split(',')[0].to_i
      else
        (@address.split(',')[0].to_i..@address.split(',')[1].to_i).each do |i|
          @current = i
        end
      end
    else
      p 'other..'
      @cmd_flg = false
    end
  end

  def _print
    puts '?' unless @cmd_flg
  end

end

Ed.new
