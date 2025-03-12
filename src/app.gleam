import gleam/bytes_tree
import gleam/erlang
import gleam/erlang/process.{type Selector, type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import lustre
import lustre/attribute
import lustre/element.{element}
import lustre/element/html.{html}
import lustre/server_component
import mist.{
  type Connection, type ResponseData, type WebsocketConnection,
  type WebsocketMessage,
}
import role_lottery
import simplifile

pub fn main() {
  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      case request.path_segments(req) {
        // Set up the websocket connection to the client. This is how we send
        // DOM updates to the browser and receive events from the client.
        ["role_lottery"] ->
          mist.websocket(
            request: req,
            on_init: socket_init,
            on_close: socket_close,
            handler: socket_update,
          )

        // We need to serve the server component runtime. There's also a minified
        // version of this script for production.
        ["lustre-server-component.mjs"] -> {
          let assert Ok(priv) = erlang.priv_directory("lustre")
          let path = priv <> "/static/lustre-server-component.mjs"

          mist.send_file(path, offset: 0, limit: None)
          |> result.map(fn(script) {
            response.new(200)
            |> response.prepend_header("content-type", "application/javascript")
            |> response.set_body(script)
          })
          |> result.lazy_unwrap(fn() {
            response.new(404)
            |> response.set_body(mist.Bytes(bytes_tree.new()))
          })
        }

        // We need to serve the server component runtime. There's also a minified
        // version of this script for production.
        ["app.css"] -> {
          let assert Ok(priv) = erlang.priv_directory("role_lottery")
          let path = priv <> "/static/app.css"

          mist.send_file(path, offset: 0, limit: None)
          |> result.map(fn(stylesheet) {
            response.new(200)
            |> response.prepend_header("content-type", "text/css")
            |> response.set_body(stylesheet)
          })
          |> result.lazy_unwrap(fn() {
            response.new(404)
            |> response.set_body(mist.Bytes(bytes_tree.new()))
          })
        }

        // For all other requests we'll just serve some HTML that renders the
        // server component.
        _ ->
          response.new(200)
          |> response.prepend_header("content-type", "text/html")
          |> response.set_body(
            simplifile.read("index.html")
            |> result.unwrap("")
            // html([], [
            //   html.head([], [
            //     html.link([
            //       attribute.rel("stylesheet"),
            //       attribute.href(
            //         "https://cdn.jsdelivr.net/gh/lustre-labs/ui/priv/styles.css",
            //       ),
            //     ]),
            //     html.script(
            //       [
            //         attribute.type_("module"),
            //         attribute.src("/lustre-server-component.mjs"),
            //       ],
            //       "",
            //     ),
            //   ]),
            //   html.body([], [
            //     element(
            //       "lustre-server-component",
            //       [server_component.route("/role_lottery")],
            //       [html.p([], [html.text("This is a slot")])],
            //     ),
            //   ]),
            // ])
            // |> element.to_document_string_builder
            |> bytes_tree.from_string
            // |> bytes_tree.from_string_tree
            |> mist.Bytes,
          )
      }
    }
    |> mist.new
    |> mist.port(3000)
    |> mist.start_http

  process.sleep_forever()
}

//

type RoleLottery =
  Subject(lustre.Action(role_lottery.Msg, lustre.ServerComponent))

fn socket_init(
  _,
) -> #(RoleLottery, Option(Selector(lustre.Patch(role_lottery.Msg)))) {
  let self = process.new_subject()
  let app = role_lottery.app()
  let assert Ok(role_lottery) = lustre.start_actor(app, 0)

  process.send(
    role_lottery,
    server_component.subscribe(
      // server components can have many connected clients, so we need a way to
      // identify this client.
      "ws",
      // this callback is called whenever the server component has a new patch
      // to send to the client. here we json encode that patch and send it to
      // via the websocket connection.
      //
      // a more involved version would have us sending the patch to this socket's
      // subject, and then it could be handled (perhaps with some other work) in
      // the `mist.Custom` branch of `socket_update` below.
      process.send(self, _),
    ),
  )

  #(
    // we store the server component's `Subject` as this socket's state so we
    // can shut it down when the socket is closed.
    role_lottery,
    Some(process.selecting(process.new_selector(), self, fn(a) { a })),
  )
}

fn socket_update(
  role_lottery: RoleLottery,
  conn: WebsocketConnection,
  msg: WebsocketMessage(lustre.Patch(role_lottery.Msg)),
) {
  case msg {
    mist.Text(json) -> {
      // we attempt to decode the incoming text as an action to send to our
      // server component runtime.
      let action = json.decode(json, server_component.decode_action)

      case action {
        Ok(action) -> process.send(role_lottery, action)
        Error(_) -> Nil
      }

      actor.continue(role_lottery)
    }

    mist.Binary(_) -> actor.continue(role_lottery)
    mist.Custom(patch) -> {
      let assert Ok(_) =
        patch
        |> server_component.encode_patch
        |> json.to_string
        |> mist.send_text_frame(conn, _)

      actor.continue(role_lottery)
    }
    mist.Closed | mist.Shutdown -> actor.Stop(process.Normal)
  }
}

fn socket_close(role_lottery: RoleLottery) {
  process.send(role_lottery, lustre.shutdown())
}
