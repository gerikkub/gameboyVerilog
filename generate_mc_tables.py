#!/usr/bin/python

import json
import sys
import math

# Checks if an entry in the control signal json file is correct
def isValidSignalEntry(cs_entry, name):

    if not "type" in cs_entry:
        print '"type" field not found in entry: {0}'.format(name)
        return False

    if cs_entry["type"] == "num":
        if not "bits" in cs_entry:
            print '"bits" field not found in entry: {0}'.format(name)
            return False

        if cs_entry["bits"] is int:
                print '"bits" field has incorrect type {0} in entry: {1}'.format(type(cs_entry["bits"]), name)
                return False

        bits = cs_entry["bits"]

        if "default" in cs_entry:
            if cs_entry["default"] is int:
                print '"default" field has incorrect type {0} in entry: {1}'.format(type(cs_entry["default"], name))
                return False

            value = cs_entry["default"]
            bits = cs_entry["bits"]

            if (value < 0 or value > (2**bits)):
                print '"default" field is out-of-range [0,{0}] in entry: {1}'.format((2**bits)-1, name)
                return False

    elif cs_entry["type"] == "mux":
        if not "values" in cs_entry:
            print '"values" field not found in entry: {0}'.format(name)
            return False

        if cs_entry["values"] is list:
            print '"values" field has incorrect type {0} in entry: {1}'.format(type(cs_entry["values"]), name)
            return False
        
        values = cs_entry["values"]

        if ("default" in cs_entry):
                if cs_entry["default"] is unicode:
                    print '"default" field has incorrect type {0} in entry: {1}'.format(type(cs_entry["default"]), name)
                    return False

                if not cs_entry["default"] in values:
                    print '"default" value is not found in values array in entry: {0}'.format(name)
                    return False
    else:
        print 'Unknown type {0} in entry: {1}'.format(cs_entry["type"], name)
        return False

    return True

# Generates the signal->bits, and the signal->position tables as well
# as the default_bitfield value used by the subop table
def generateSignalTable(cs_json_name):

    # Load the JSON file
    cs_data = open(cs_json_name)
    cs_json = json.load(cs_data)

    default_bitfield = 0

    # Holds the number of bits needed for a signal
    bits = int(0)

    # Keeps track of the current position in the bitfield
    # for a signal
    position = int(0)

    # Dictionary containing the signal name as the key and the
    # number of bits used by the signal as the value
    cs_bits_dict = {}

    # Dictionary containing the signal name as the key and the
    # signal's position on the bitfield as the value
    cs_position_dict = {}

    # Dictionary containing the signal name as the key and the
    # signal's values list as the value. If the type in "num" then
    # the signal will not have an entry in the dictionary
    cs_values_dict = {}


    for cs_entry_name in cs_json:

        cs_entry = cs_json[cs_entry_name]

        if not isValidSignalEntry(cs_entry, cs_entry_name):
            return False, cs_bits_dict, cs_position_dict, cs_values_dict, default_bitfield

        if (cs_entry["type"] == "num"):
            # The number of necessary bits is provided in the entry
            bits = cs_entry["bits"]

            # Modify the default_bitfield if applicable
            if "default" in cs_entry:
                default_bitfield = default_bitfield | (cs_entry["default"] << int(position))


        elif (cs_entry["type"] == "mux"):
            # Calculates the number of necessary bits from the "values" array
            bits = int(math.ceil(math.log(len(cs_entry["values"]), 2)))

            # Modify the default_bitfield if applicable
            if "default" in cs_entry:
                def_value = cs_entry["values"].index(cs_entry["default"])

                default_bitfield = default_bitfield | (def_value << position)

            cs_values_dict[cs_entry_name] = cs_entry["values"]

        else:
            assert False, "Unknown signal type {0} for signal {1}".format((cs_entry["type"], cs_entry))

        cs_bits_dict[cs_entry_name] = int(bits)
        cs_position_dict[cs_entry_name] = int(position)
        
        position = position + bits

    return True, cs_bits_dict, cs_position_dict, cs_values_dict, default_bitfield

def getSignalValue(signal_name, signal_value, cs_bits, cs_values):

    # Holds the number value corresponding to the signal_value
    ret_num = 0

    if signal_name in cs_values:
        # The signal type is mux

        if not signal_value in cs_values[signal_name]:
            print "Unknown signal value {0} for signal {1}".format(signal_value, signal_name)
            return False, ret_num


        # Gets singal_values's position in the signal array. The position
        # corresponds to the signals value
        ret_num = cs_values[signal_name].index(signal_value)

    else:
        # This signal type is num

        if (signal_value > (2**cs_bits[signal_name]) - 1) or (signal_value < 0):
            print "Invalid signal value {0} for signal {1}".format(signal_value, signal_name)
            return False, ret_num

        ret_num = signal_value

    return True, ret_num
            
         


# Generates a dictionary with the subop name as the key and the position in the
# subop table as the value
def generateSubopTable(subop_json, cs_bits, cs_position, cs_values, default_bitfield):
    
    subop_bitfield_dict = {}
    subop_position_dict = {}

    position = int(0)

    for subop_entry_name in subop_json:
        
        subop_entry = subop_json[subop_entry_name]

        bitfield = default_bitfield

        for signal_name in subop_entry:
            if not signal_name in cs_bits:
                print "Unknown signal name {0} in subop {1}".format((signal_name, subop_entry_name))
                return False, subop_bitfield_dict, subop_position_dict

            sig_bits = cs_bits[signal_name]
            sig_position = cs_position[signal_name]
            
            # Creates a mask to insert the correct signal bits
            # For example, if (sig_bits = 2) and (sig_position = 5)
            # Then sig_mask = 0b1100000
            sig_mask = ~ (((2**sig_bits) - 1) << sig_position)

            bitfield = bitfield & sig_mask

            status, sig_value = getSignalValue(signal_name, subop_entry[signal_name], cs_bits, cs_values)

            if status == False:
                return False, subop_bitfield_dict, subop_position_dict

            # Set the appropriate bits in the bitfield
            bitfield = bitfield | (sig_value << sig_position)

        # Write the bitfield to the subop_bitfield_dict
        subop_bitfield_dict[subop_entry_name] = bitfield

        # Write the position to the subop_position_dict
        subop_position_dict[subop_entry_name] = position

        position = position + 1

    return True, subop_bitfield_dict, subop_position_dict



def main():

    status, cs_bits_dict, cs_position_dict, cs_values_dict, default_bitfield = generateSignalTable(sys.argv[1])

    if status == False:
        return

    print cs_position_dict


    print default_bitfield

    microcode_data = open(sys.argv[2])
    microcode_json = json.load(microcode_data)

    status, subop_bitfield_dict, subop_position_dict = generateSubopTable(microcode_json["subop"], cs_bits_dict, cs_position_dict, cs_values_dict, default_bitfield)

    if status == False:
        return

    print subop_bitfield_dict

    print subop_position_dict

if __name__ == "__main__":
    main()






