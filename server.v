import xwrap
import net
import time

const dpy = C.XOpenDisplay(unsafe { nil })
const root = C.XDefaultRootWindow(dpy)
const width = 1300
const height = 700

fn main() {
        mut server := net.listen_tcp(.ip, ':40001')!
        for {
                println('Waiting for a new session')
                mut session := server.accept()!
                spawn server_handle(mut session)
        }
}

@[direct_array_access]
fn server_handle(mut ses net.TcpConn) {
	mut pixels := []u8{len:width*height*3} // rgb
        defer {
                println(time.now())
                println('closing a session')
                ses.close() or { panic(err) }
        }
	ses.set_read_timeout(time.second)
	send: for {
		a := ses.read_line()#[..-1]
		if a == '' {
			break send
		}
		ximg := C.XGetImage(dpy, root, 0, 0, width, height, C.AllPlanes, C.ZPixmap) // bgra
		for i in 0..width*height {
			pixels[i*3] = ximg.data[i*4+2]
			pixels[i*3+1] = ximg.data[i*4+1]
			pixels[i*3+2] = ximg.data[i*4]
		}
		C.XDestroyImage(ximg)
		ses.write(pixels) or {panic(err)}
	}
}
