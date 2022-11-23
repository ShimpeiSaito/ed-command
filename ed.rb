# frozen_string_literal: true

require 'optparse'

class Ed
  def initialize()
    @input = '' # コマンドの入力
    @cmd_flg = true # 適切なコマンドかのフラグ
    @address = '' # コマンドのアドレス部
    @command = '' # コマンドのコマンド部
    @parameter = '' # コマンドのパラメータ部
    @buffer = [] # バッファ
    @current = 0 # カレント行
    @prompt = '' # プロンプト
    @file = ''

    # プロントプトのオプションがあれば設定する
    OptionParser.new do |op|
      op.banner = 'Usage: ed.rb [options]'
      op.on('-p PROMPT') do |p|
        @prompt = p
      end
      op.parse!(ARGV)
    end

    # ファイルがあれば読み込み、なければ標準入力を受け付ける
    begin
      unless ARGV.empty?
        @file = ARGF.filename
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
    print @prompt
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
      @parameter = Regexp.last_match(3).strip
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

    return @address = "1,#{@buffer.length}" if @address[0] == ','

    sp_address = @address.split(',')

    address_1 = sp_address[0]
    address_2 = sp_address[1]

    case sp_address[0]
    when '.'
      address_1 = @current.to_s
    when '$'
      address_1 = @buffer.length.to_s
    when ';'
      return @address = "#{@current},#{@buffer.length}"
    end

    case sp_address[1]
    when '.'
      address_2 = @current.to_s
    when '$'
      address_2 = @buffer.length.to_s
    end

    if sp_address[1].nil?
      @address = address_1
      return
    end
    @address = "#{address_1},#{address_2}"
  end

  # アドレスのバリデーション
  def address_validate
    @address = @current.to_s if @address.nil?

    sp_address = @address.split(',')

    # アドレスに0があるならエラー
    if sp_address.length.positive?
      if sp_address[0].to_i.zero?
        @cmd_flg = false
        return true
      end
    elsif sp_address.length > 1
      if sp_address[1].to_i.zero?
        @cmd_flg = false
        return true
      end
    end
    false
  end

  def get_inputs
    lines = []
    loop do
      lines << $stdin.gets.chomp
      if lines.last == '.'
        lines.pop
        break
      end
    end
    lines
  end

  def command_q
    unless @address == '' || @parameter == ''
      @cmd_flg = false
      return
    end
    exit
  end

  def command_p
    return if address_validate

    sp_address = @address.split(',')

    if sp_address.length == 1

      if sp_address[0].to_i <= @buffer.length
        puts @buffer[sp_address[0].to_i - 1]
        @current = sp_address[0].to_i
      else
        @cmd_flg = false
        return
      end
    elsif sp_address[1].to_i <= @buffer.length
      (sp_address[0].to_i - 1..sp_address[1].to_i - 1).each do |i|
        puts @buffer[i]
      end
      @current = sp_address[1].to_i
    else
      @cmd_flg = false
      return
    end
  end

  def command_n
    return if address_validate

    sp_address = @address.split(',')

    if sp_address.length == 1
      if sp_address[0].to_i <= @buffer.length
        puts "#{sp_address[0].to_i}    #{@buffer[sp_address[0].to_i - 1]}"
        @current = sp_address[0].to_i
      else
        @cmd_flg = false
        return
      end
    elsif sp_address[1].to_i <= @buffer.length
      (sp_address[0].to_i - 1..sp_address[1].to_i - 1).each do |i|
        puts "#{i + 1}    #{@buffer[i]}"
      end
      @current = sp_address[1].to_i
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

    sp_address = @address.split(',')

    del_targets = []
    if sp_address.length == 1
      if sp_address[0].to_i <= @buffer.length
        @buffer.delete_at(sp_address[0].to_i - 1)
        @current = sp_address[0].to_i
      else
        @cmd_flg = false
        return
      end
    elsif sp_address[1].to_i <= @buffer.length
      (sp_address[0].to_i..sp_address[1].to_i).each do |i|
        del_targets << i
      end
      @buffer.slice!(sp_address[0].to_i - 1, del_targets.length)
      @current = sp_address[1].to_i
    else
      @cmd_flg = false
      return
    end
  end

  # 改行コマンド
  def command_
    @address = (@current + 1).to_s if @address.nil?

    return if address_validate

    sp_address = @address.split(',')

    if sp_address.length == 1
      if sp_address[0].to_i <= @buffer.length
        @current = sp_address[0].to_i
      else
        @cmd_flg = false
        return
      end
    elsif sp_address[1].to_i <= @buffer.length
      (sp_address[0].to_i..sp_address[1].to_i).each do |i|
        @current = i
      end
    else
      @cmd_flg = false
      return
    end
    puts @buffer[@current - 1]
  end

  def command_a
    return if address_validate

    sp_address = @address.split(',')

    lines = get_inputs

    if sp_address.length == 1
      if sp_address[0].to_i <= @buffer.length
        lines.each_with_index do |l, i|
          @buffer.insert(sp_address[0].to_i + i, l)
        end
        @current = sp_address[0].to_i + lines.length
      else
        @cmd_flg = false
        return
      end
    elsif sp_address[1].to_i <= @buffer.length
      lines.each_with_index do |l, i|
        @buffer.insert(sp_address[1].to_i + i, l)
      end
      @current = sp_address[1].to_i + lines.length
    else
      @cmd_flg = false
      return
    end
  end

  def command_c
    command_d
    @address = @address.split(',')[0]
    command_i
  end

  def command_f
    @file = @parameter unless @parameter == ''
    puts @file
  end

  def command_i
    return if address_validate

    sp_address = @address.split(',')

    lines = get_inputs

    if sp_address.length == 1
      if sp_address[0].to_i <= @buffer.length
        lines.each_with_index do |l, i|
          @buffer.insert(sp_address[0].to_i + i - 1, l)
        end
        @current = sp_address[0].to_i + lines.length
      else
        @cmd_flg = false
        return
      end
    elsif sp_address[1].to_i <= @buffer.length
      lines.each_with_index do |l, i|
        @buffer.insert(sp_address[1].to_i + i - 1, l)
      end
      @current = sp_address[1].to_i + lines.length
    else
      @cmd_flg = false
      return
    end
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
