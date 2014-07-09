require 'csv'

module LeankitConvert
  class CsvFile
    def open(file_name, header)
      @file_name = file_name
      @header = header
    end

    def put(hash)
      hash.each do |k,v|
        hash[k] = v.to_s
      end
      if @records.nil?
        @records = load_data
      end

      record = find_record(hash[@header[0]])
      if record
        hash.each do |key, value|
          record[key] = value
        end
      else
        @records << hash
      end
    end

    def close
      File.open(@file_name, "w") do |f|
        f.write(@header.join(',') + "\n")
        @records.each do |record|
          line = ""
          @header.each do |key|
            line << record[key].to_s + ","
          end
          f.write("#{line.chomp(',')}\n")
        end
      end
    end

    private
    def load_data
      records = []
      if File.exists?(@file_name)
        # FIXME: a kanban_metrics_gem-ben pont ilyen van - onnan masoltam
        CSV.foreach(@file_name, {:force_quotes => true, :headers => true}) do |row|
          unless row.header_row?
            data = {}
            row.headers.each do |header|
              if (row[header] && !row[header].empty?)
                data[header.sub(" ", "_").to_sym] = row[header]
              end
            end
            records << data
          end
        end
      end
      records
    end

    def find_record(id)
      @records.each do |record|
        if record[@header[0]] == id
          return record
        end
      end
      nil
    end
  end
end
