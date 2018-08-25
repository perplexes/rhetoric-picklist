require_relative './picklist'

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
    orders_string = req.params["orders"][:tempfile].read
    line_items_string = req.params["line_items"][:tempfile].read
    lines = Picklist.parse(orders_string, line_items_string)

    [200, {'Content-Type'=>'text/plain'}, StringIO.new(lines.join("\n"))]
  else
    [404, {'Content-Type'=>'text/plain'}, StringIO.new("Sry")]
  end
}
