#ifndef VRPNCONTROLLER_H
#define VRPNCONTROLLER_H

#include <godot_cpp/classes/node3d.hpp>

// Based on the Xsite Unreal plugin and ported to Godot
// https://github.com/bnlrnz/xsite_ue

#include <memory>
#include <cstdint>
#include <map>
#include "include/vrpn_Connection.h" // for vrpn_Connection, etc
#include "include/vrpn_Shared.h"     // for vrpn_SleepMsecs
#include "include/vrpn_Tracker.h"
#include "include/vrpn_Button.h"
#include "include/vrpn_Analog.h"

#define ANALOG_CHANNELS 2 // we only need 2 channels for our flystick

enum ButtonState
{
    Pressed = 1,
    Released = 0
};

namespace godot {

class VRPNController : public Node3D {
   GDCLASS(VRPNController, Node3D)

public:
   typedef struct _TrackerData
    {
        double Pos[3];
        double Quat[4];
    } TrackerData;

    typedef struct _AnalogData
    {
        int    NumChannels;
        double Channel[ANALOG_CHANNELS];
    } AnalogData;

    // stores the recently received data
    std::map<int, VRPNController::TrackerData>  TrackerDataMap;
    std::map<int, ButtonState>                  ButtonDataMap;
    AnalogData AnalogDataField{};

private:

   std::shared_ptr<vrpn_Connection> connection  = nullptr;

   std::shared_ptr<vrpn_Tracker_Remote> tracker = nullptr;
   std::shared_ptr<vrpn_Button_Remote> button   = nullptr;
   std::shared_ptr<vrpn_Analog_Remote> analog   = nullptr;

protected:
   static void _bind_methods();

public:
   VRPNController();
   ~VRPNController();

   void _process(float delta);

   void init(const godot::String& Device, const godot::String& HostIP, uint32_t Port = vrpn_DEFAULT_LISTEN_PORT_NO);
   void poll();

   void tracker_changed(int sensor, const Vector3 &pos, const Quaternion &quat);
   void analog_changed(int num_channels, const Array &channels);
   void button_pressed(int button, bool pressed);
};

}

#endif
