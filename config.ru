require 'pry'
require 'csv'
class Array
  def count_by
    inject({}) do |accum, elem|
      key = yield elem
      accum[key] ||= 0
      accum[key] += 1
      accum
    end
  end

  def index_by
    inject({}) do |accum, elem|
      key = yield elem
      accum[key] = elem
      accum
    end
  end
end

class String
  def blank?
    self == ""
  end
end

class Nil
  def blank?
    true
  end
end

run lambda { |env|
  req = Rack::Request.new(env)
  case req.path_info
  when '/'
    [200, {'Content-Type'=>'text/html'}, StringIO.new(<<-html
      <form action="/picklist" method="post" enctype="multipart/form-data">
        Orders:
          <input type="file" name="orders">
        Line Items:
          <input type="file" name="line_items">
        <input type="submit">
      </form>
    html
)]
  when /picklist/
    orders = CSV.parse(req.params["orders"][:tempfile].read, headers: true)
    line_items = CSV.parse(req.params["line_items"][:tempfile].read, headers: true)

    puts orders.inspect
    puts line_items.inspect

    bags_by_sku = line_items.map.to_a.reject{|li| li["Item - SKU"].blank?}.inject({}) do |accum, li|
      accum[li["Item - SKU"]] ||= 0
      accum[li["Item - SKU"]] += li["Item - Qty"].to_i
      accum
    end


    o_by_on = orders.map.to_a.index_by{|o| o["Order - Number"]};
    li_by_on = line_items.map.to_a.group_by{|li| li["Order - Number"]};

    boxes_by_sku = line_items.
    reject{|li| li["Item - SKU"].blank?}.
    flat_map do |li|
      value = [[
        li["Item - SKU"],
        o_by_on[li["Order - Number"]]["Service - Package Type"]
      ]]
      value * li["Item - Qty"].to_i
    end.count_by{|e| e}.inject({}) do |accum, ((size, package), count)|
      accum[size] ||= {}
      accum[size][package] = count
      accum
    end

    # TODO I bet we could encode this as a "package", but also not pay postage on it somehow
    bags_by_sku["medium"] += 10
    boxes_by_sku["medium"]["Franklin (set aside)"] = 10

    lines = []
    lines << "Total bags: #{bags_by_sku.values.sum}"
    lines << ""

    [
      ["5lb", "5lbs"],
      ["large", "large (16oz)"],
      ["medium", "medium (12oz)"],
      ["small", "small (8 oz)"],
      ["tiny", "tiny (4 oz)"],
    ].each do |key, label|
      bags = bags_by_sku[key]
      boxes = boxes_by_sku[key]
      lines << label
      lines << "Bags: #{bags}"
      lines << "Boxes:"
      boxes.each do |box, count|
        if box =~ /X-Large/
          box += " (set aside)"
        end

        lines << "\t#{box}: #{count}"
      end
      lines << ""
    end

    lines << ""

    orders.select{|o| o["Service - Package Type"] == "X-Large S-10696"}.each do |order|
      lis = li_by_on[order["Order - Number"]]
      lines << "To: #{order["Ship To - Name"]}"
      lines << "Order: #{order["Order - Number"]}"
      lis.each do |li|
        lines << "\t#{li["Item - SKU"]} x #{li["Item - Qty"]}"
      end
      lines << ""
    end

    [200, {'Content-Type'=>'text/plain'}, StringIO.new(lines.join("\n"))]
  else
    [404, {'Content-Type'=>'text/plain'}, StringIO.new("Sry")]
  end
}