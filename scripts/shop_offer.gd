class_name ShopOffer
extends RefCounted
## One purchasable slot in the shop (shop-scene spec). Stubs only for now;
## real charm/dice resources are wired in add-charm-framework.

enum Type { CHARM_STUB, DICE_STUB, SKIP }

var type: Type = Type.CHARM_STUB
var label: String = ""
var cost: int = 0
var sold: bool = false


static func make(p_type: Type, p_label: String, p_cost: int) -> ShopOffer:
	var o := ShopOffer.new()
	o.type = p_type
	o.label = p_label
	o.cost = p_cost
	return o
