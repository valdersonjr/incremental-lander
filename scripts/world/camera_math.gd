## Enquadramento da camera de voo — logica pura, testavel.
class_name CameraMath
extends RefCounted


## Quanto a camera sobe (px) com a nave a alt px do chao: maximo no chao (nave ~3/4 da tela, mais ceu, menos chao),
## some ate fade_alt (nave volta ao centro da tela).
static func lift(alt: float, max_lift: float, fade_alt: float) -> float:
	return max_lift * clampf(1.0 - alt / fade_alt, 0.0, 1.0)
