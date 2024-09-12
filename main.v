import gg

const dpy = C.XOpenDisplay(unsafe { nil })
const root = C.XDefaultRootWindow(dpy)
const width = 1300
const height = 700


struct App {
mut:
	ctx         &gg.Context = unsafe { nil }
	square_size int         = 10
	pixels []u8 = []u8{len:width*height*4}
	iidx int
}

fn main() {
	mut app := &App{}
	app.ctx = gg.new_context(
		create_window: true
		window_title:  '- Application -'
		user_data:     app
		init_fn: 	graphics_init
		frame_fn:      on_frame
		event_fn:      on_event
		sample_count:  2
	)

	// lancement du programme/de la fenêtre
	ximg := C.XGetImage(dpy, root, 0, 0, width, height, C.AllPlanes, C.ZPixmap) // bgra
	for i in 0..width*height {
		app.pixels[i*4] = ximg.data[i*4+2]
		app.pixels[i*4+1] = ximg.data[i*4+1]
		app.pixels[i*4+2] = ximg.data[i*4]
		app.pixels[i*4+3] = 255
	}
	app.ctx.run()
}

fn graphics_init(mut app App) {
	app.iidx = app.ctx.new_streaming_image(width, height, 4, pixel_format: .rgba8)
}

@[direct_array_access]
fn on_frame(mut app App) {
	// Draw
	ximg := C.XGetImage(dpy, root, 0, 0, width, height, C.AllPlanes, C.ZPixmap) // bgra
	for i in 0..width*height {
		app.pixels[i*4] = ximg.data[i*4+2]
		app.pixels[i*4+1] = ximg.data[i*4+1]
		app.pixels[i*4+2] = ximg.data[i*4]
		app.pixels[i*4+3] = 255
	}
	app.ctx.begin()
	mut istream_image := app.ctx.get_cached_image_by_idx(app.iidx)
	istream_image.update_pixel_data(unsafe{&u8(app.pixels.data)})
	app.ctx.draw_image(0, 0, width, height, istream_image)
	app.ctx.end()
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
