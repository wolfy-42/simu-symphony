The video source and sink BFMs provide AXI4-Stream video interfaces, defined in
interfaces_axi4s_video.sv. 

fidus_video_bfm_pkg.sv contains a class representing a video frame. It can be used to generate test
frames (colour bar, or counters), compare frames, and read/write raw pixel dumps from/to disk. These
raw pixel dumps can be converted to tiff images with "raw2tiff", see the tc_vidgen test case for
sample usage.

The source bfm transmits video frames on an axis master interface. These are provided as video_frame
classes (fidus_video_bfm_pkg.sv).

The sink bfm forks a monitor that receives video frames on its slave axis interface. The latest
received frame is stored as a video_frame class instance. The bfm calculates parity and returns the
embedded sequence counter if an F_Video_BIST embedder IP is used to insert these.
