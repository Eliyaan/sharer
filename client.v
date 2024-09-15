import xwrap
import gg
import net

const width = 1300
const height = 700


struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
        con        net.TcpConn
	square_size int         = 10
	rawp []u8 = []u8{len:width*height*3}
	pixels []u8 = []u8{len:width*height*4, init:255}
	iidx int
}

fn main() {
	mut app := &App{con: net.dial_tcp('127.0.0.0:40001')!}
        defer {
                println('closing the session')
                app.con.close() or { panic(err) }
        }
	app.ctx = gg.new_context(
		create_window: true
		window_title:  '- Application -'
		user_data:     app
		init_fn: 	graphics_init
		frame_fn:      on_frame
		event_fn:      on_event
		sample_count:  2
	)
	app.ctx.run()
}

fn graphics_init(mut app App) {
	app.iidx = app.ctx.new_streaming_image(width, height, 4, pixel_format: .rgba8)
	app.con.write_string("ping\n") or {panic(err)}
}

@[direct_array_access]
fn on_frame(mut app App) {
	// Draw
	mut pix := 0
	for pix < app.rawp.len {
		pix += app.con.read(mut app.rawp[pix..]) or {panic(err)}
	}
	for i in 0..width*height {
		app.pixels[i*4] = app.rawp[i*3]
		app.pixels[i*4+1] = app.rawp[i*3+1]
		app.pixels[i*4+2] = app.rawp[i*3+2]
	}
	app.ctx.begin()
	mut istream_image := app.ctx.get_cached_image_by_idx(app.iidx)
	istream_image.update_pixel_data(unsafe{&u8(app.pixels.data)})
	app.ctx.draw_image(0, 0, width, height, istream_image)
	app.ctx.show_fps()
	app.ctx.end()
	app.con.write_string("ping\n") or {panic(err)}
}

fn on_event(e &gg.Event, mut app App) {
	if e.char_code != 0 {
		println(e.char_code)
	}
	match e.typ {
		.key_down {
			match e.key_code {
				.escape { app.ctx.quit() }
				else {}
			}
		}
		else {}
	}
}
