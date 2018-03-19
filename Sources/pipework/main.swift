import PerfectLib
import PerfectHTTP
import PerfectHTTPServer

class FilterFirst: HTTPRequestFilter {
  public func filter(request: HTTPRequest, response: HTTPResponse,
                     callback: (HTTPRequestFilterResult) -> ()) {
    guard let input = request.param(name: "input"),
      let x = Int(input) else {
      response.setHeader(.contentType, value: "text/plain")
      response.appendBody(string: "input is missing\n")
      response.completed()
      callback(.halt(request, response))
      return
    }
    request.scratchPad["x"] = x
    callback(.continue(request, response))
  }
}

class FilterSecond: HTTPRequestFilter {
  public func filter(request: HTTPRequest, response: HTTPResponse,
                     callback: (HTTPRequestFilterResult) -> ()) {
    guard let x = request.scratchPad["x"] as? Int else {
        response.setHeader(.contentType, value: "text/plain")
        response.appendBody(string: "x is missing\n")
        response.completed()
        callback(.halt(request, response))
        return
    }
    request.scratchPad["y"] = x * 2;
    callback(.continue(request, response))
  }
}

class FilterThird: HTTPRequestFilter {
  public func filter(request: HTTPRequest, response: HTTPResponse,
                     callback: (HTTPRequestFilterResult) -> ()) {
    guard let y = request.scratchPad["y"] as? Int else {
      response.setHeader(.contentType, value: "text/plain")
      response.appendBody(string: "y is missing\n")
      response.completed()
      callback(.halt(request, response))
      return
    }
    request.scratchPad["z"] = y * 2;
    callback(.continue(request, response))
  }
}

let server = HTTPServer()
server.serverPort = 8181
let requestFilters: [(HTTPRequestFilter, HTTPFilterPriority)] =
  [
    (FilterFirst(), HTTPFilterPriority.high),
    (FilterSecond(), HTTPFilterPriority.medium),
    (FilterThird(), HTTPFilterPriority.low),
  ]

server.setRequestFilters(requestFilters)
var routes = Routes()
routes.add(Route(method: .get, uri: "/**", handler: {
  request, response in
  response.setHeader(.contentType, value: "text/json")
  guard let x = request.scratchPad["x"] as? Int,
    let y = request.scratchPad["y"] as? Int,
    let z = request.scratchPad["z"] as? Int
    else {
      response.appendBody(string: "unexpected\n")
      response.completed()
      return
  }
  response.appendBody(string: "x = \(x), y = \(y), z = \(z)\n")
  response.completed()
}))

server.addRoutes(routes)
try! server.start()
