class Ed
  # TODO: 全体的なリファクタリング
  def initialize()
    @input = '' # コマンドの入力
    @cmd_flg = true # 適切なコマンドかのフラグ
    @address = '' # コマンドのアドレス部
    @command = '' # コマンドのコマンド部
    @parameter = '' # コマンドのパラメータ部
    @buffer = []
    @current = 0

    begin
      unless ARGV.empty?
        @buffer = ARGF.readlines
        @current = @buffer.length # カレント行は最後の行
      end
    rescue StandardError
      puts "#{ARGF.filename}: No such file or directory"
    end

    loop do
      _read
      _eval
      _print
    end
  end

  def _read
    @input = $stdin.gets.chomp
  end

  def _eval
    addr = '(?:\d+|[.$,;]|\/.*\/)'
    cmnd = '(?:wq|[acdfijnpqrw=]|\z)'
    prmt = '(?:.*)'
    if @input =~ /\A(#{addr}(?:,#{addr})?)?(#{cmnd})(#{prmt})?\z/
      @address = Regexp.last_match(1)
      @command = Regexp.last_match(2)
      @parameter = Regexp.last_match(3)
    else
      @cmd_flg = false
      return
    end

    begin
      address_replace
      p @address, @command, @parameter
      send("#{@command}_command")
    rescue StandardError
      @cmd_flg = false
    end
  end

  def address_replace
    return if @address.nil?

    address_1 = @address.split(',')[0]
    address_2 = @address.split(',')[1]

    case @address.split(',')[0]
    when '.'
      address_1 = @current.to_s
    when '$'
      address_1 = @buffer.length.to_s
    when ','
      @address = "1,#{@buffer.length}"
      return
    when ';'
      @address = "#{@current},#{@buffer.length}"
      return
    end

    case @address.split(',')[1]
    when '.'
      address_2 = @current.to_s
    when '$'
      address_2 = @buffer.length.to_s
    end

    if @address.split(',')[1].nil?
      @address = address_1
      return
    end
    @address = "#{address_1},#{address_2}"
  end

  def address_validate
    if @address.split(',')[0].to_i.zero?
      @cmd_flg = false
      true
    end
  end

  def q_command
    unless @address == '' || @parameter == ''
      @cmd_flg = false
      return
    end
    exit
  end

  def p_command
    @address = @current.to_s if @address.nil?

    return if address_validate

    if @address.split(',').length == 1
      if @address.split(',')[0].to_i - 1 <= @buffer.length
        puts @buffer[@address.split(',')[0].to_i - 1]
        @current = @address.split(',')[0].to_i
      else
        @cmd_flg = false
      end
    elsif @address.split(',')[1].to_i - 1 <= @buffer.length
      (@address.split(',')[0].to_i - 1..@address.split(',')[1].to_i - 1).each do |i|
        puts @buffer[i]
      end
      @current = @address.split(',')[1].to_i
    else
      @cmd_flg = false
    end
  end

  def n_command
    @address = @current if @address.nil?

    return if address_validate

    if @address.split(',').length == 1
      if @address.split(',')[0].to_i - 1 <= @buffer.length
        puts "#{@address.split(',')[0].to_i}    #{@buffer[@address.split(',')[0].to_i - 1]}"
        @current = @address.split(',')[0].to_i
      else
        @cmd_flg = false
      end
    elsif @address.split(',')[1].to_i - 1 <= @buffer.length
      (@address.split(',')[0].to_i - 1..@address.split(',')[1].to_i - 1).each do |i|
        puts "#{i}    #{@buffer[i]}"
      end
      @current = @address.split(',')[1].to_i
    else
      @cmd_flg = false
    end
  end

  def d_command
    return if address_validate

    unless @parameter == ''
      @cmd_flg = false
      return
    end

    del_targets = []
    if @address.split(',').length == 1
      if @address.split(',')[0].to_i - 1 <= @buffer.length
        @buffer.delete_at(@address.split(',')[0].to_i - 1)
        @current = @address.split(',')[0].to_i
      else
        @cmd_flg = false
      end
    elsif @address.split(',')[1].to_i - 1 <= @buffer.length
      (@address.split(',')[0].to_i..@address.split(',')[1].to_i).each do |i|
        del_targets << i
      end
      @buffer.slice!(@address.split(',')[0].to_i - 1, del_targets.length)
      @current = @address.split(',')[1].to_i
    else
      @cmd_flg = false
    end
  end

  def _command
    if @address.split(',').length == 1
      if @address.split(',')[0].to_i - 1 <= @buffer.length
        @current = @address.split(',')[0].to_i
      else
        @cmd_flg = false
      end
    elsif @address.split(',')[1].to_i - 1 <= @buffer.length
      (@address.split(',')[0].to_i..@address.split(',')[1].to_i).each do |i|
        @current = i
      end
    else
      @cmd_flg = false
    end
  end

  def _print
    puts '?' unless @cmd_flg
    @cmd_flg = true
  end
end

Ed.new
