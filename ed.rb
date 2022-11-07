class Ed
  # TODO: 全体的なリファクタリング
  def initialize()
    @input = '' # コマンドの入力
    @cmd_flg = true # 適切なコマンドかのフラグ
    @address = '' # コマンドのアドレス部
    @command = '' # コマンドのコマンド部
    @parameter = '' # コマンドのパラメータ部
    @buffer = [] # バッファ
    @current = 0 # カレント行

    # ファイルがあれば読み込み、なければ標準入力を受け付ける
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

  # コマンドの入力を受け取る
  def _read
    @input = $stdin.gets.chomp
  end

  # コマンドの解析と処理
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
      send("command_#{@command}")
    rescue StandardError
      @cmd_flg = false
      nil
    end
  end

  # アドレスの記号を数値に変換
  def address_replace
    return if @address.nil?

    if @address[0] == ','
      @address = "1,#{@buffer.length}"
      return
    end

    address_1 = @address.split(',')[0]
    address_2 = @address.split(',')[1]

    case @address.split(',')[0]
    when '.'
      address_1 = @current.to_s
    when '$'
      address_1 = @buffer.length.to_s
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

  # アドレスのバリデーション
  def address_validate
    # アドレスに0があるならエラー
    if @address.split(',').length.positive?
      if @address.split(',')[0].to_i.zero?
        @cmd_flg = false
        return true
      end
    elsif @address.split(',').length > 1
      if @address.split(',')[1].to_i.zero?
        @cmd_flg = false
        return true
      end
    end
    false
  end

  def command_q
    unless @address == '' || @parameter == ''
      @cmd_flg = false
      return
    end
    exit
  end

  def command_p
    @address = @current.to_s if @address.nil?

    return if address_validate

    if @address.split(',').length == 1

      if @address.split(',')[0].to_i <= @buffer.length
        puts @buffer[@address.split(',')[0].to_i - 1]
        @current = @address.split(',')[0].to_i
      else
        @cmd_flg = false
        return
      end
    elsif @address.split(',')[1].to_i <= @buffer.length
      (@address.split(',')[0].to_i - 1..@address.split(',')[1].to_i - 1).each do |i|
        puts @buffer[i]
      end
      @current = @address.split(',')[1].to_i
    else
      @cmd_flg = false
      return
    end
  end

  def command_n
    @address = @current.to_s if @address.nil?

    return if address_validate

    if @address.split(',').length == 1
      if @address.split(',')[0].to_i <= @buffer.length
        puts "#{@address.split(',')[0].to_i}    #{@buffer[@address.split(',')[0].to_i - 1]}"
        @current = @address.split(',')[0].to_i
      else
        @cmd_flg = false
        return
      end
    elsif @address.split(',')[1].to_i <= @buffer.length
      (@address.split(',')[0].to_i - 1..@address.split(',')[1].to_i - 1).each do |i|
        puts "#{i}    #{@buffer[i]}"
      end
      @current = @address.split(',')[1].to_i
    else
      @cmd_flg = false
      return
    end
  end

  def command_d
    return if address_validate

    unless @parameter == ''
      @cmd_flg = false
      return
    end

    del_targets = []
    if @address.split(',').length == 1
      if @address.split(',')[0].to_i <= @buffer.length
        @buffer.delete_at(@address.split(',')[0].to_i - 1)
        @current = @address.split(',')[0].to_i
      else
        @cmd_flg = false
        return
      end
    elsif @address.split(',')[1].to_i <= @buffer.length
      (@address.split(',')[0].to_i..@address.split(',')[1].to_i).each do |i|
        del_targets << i
      end
      @buffer.slice!(@address.split(',')[0].to_i - 1, del_targets.length)
      @current = @address.split(',')[1].to_i
    else
      @cmd_flg = false
      return
    end
  end

  # 改行コマンド
  def command_
    @address = (@current + 1).to_s if @address.nil?

    return if address_validate

    if @address.split(',').length == 1
      if @address.split(',')[0].to_i <= @buffer.length
        @current = @address.split(',')[0].to_i
      else
        @cmd_flg = false
        return
      end
    elsif @address.split(',')[1].to_i <= @buffer.length
      (@address.split(',')[0].to_i..@address.split(',')[1].to_i).each do |i|
        @current = i
      end
    else
      @cmd_flg = false
      return
    end
    puts @buffer[@current - 1]
  end

  def command_a
    @address = @current.to_s if @address.nil?

    return if address_validate

    lines = []
    loop do
      lines << $stdin.gets.chomp
      if lines.last == '.'
        lines.pop
        break
      end
    end

    if @address.split(',').length == 1
      if @address.split(',')[0].to_i <= @buffer.length
        lines.each_with_index do |l, i|
          @buffer.insert(@address.split(',')[0].to_i + i, l)
        end
        @current = @address.split(',')[0].to_i + lines.length
      else
        @cmd_flg = false
        return
      end
    elsif @address.split(',')[1].to_i <= @buffer.length
      lines.each_with_index do |l, i|
        @buffer.insert(@address.split(',')[1].to_i + i, l)
      end
      @current = @address.split(',')[1].to_i + lines.length
    else
      @cmd_flg = false
      return
    end
  end

  def command_c
    # TODO: Implement me.
  end

  def command_f
    # TODO: Implement me.
  end

  def command_i
    # TODO: Implement me.
  end

  def command_j
    # TODO: Implement me.
  end

  def command_w
    # TODO: Implement me.
  end

  def command_wq
    # TODO: Implement me.
  end

  def command_=
    # TODO: Implement me.
  end

  # エラー時に?を表示
  def _print
    puts '?' unless @cmd_flg
    @cmd_flg = true
  end
end

Ed.new
