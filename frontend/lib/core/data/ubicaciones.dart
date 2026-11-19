import 'ciudades_uy_br.dart';

/// Paises y ciudades para el registro y el perfil. Uruguay y Brasil tienen
/// todas sus localidades (ver ciudades_uy_br.dart); el resto, las principales.
const Map<String, List<String>> ciudadesPorPais = {
  'Uruguay': ciudadesUruguay,
  'Argentina': [
    'Buenos Aires (CABA)', 'Bahía Blanca', 'Catamarca', 'Comodoro Rivadavia', 'Córdoba', 'Corrientes',
    'Formosa', 'La Plata', 'La Rioja', 'Mar del Plata', 'Mendoza', 'Neuquén', 'Paraná', 'Posadas',
    'Rawson', 'Resistencia', 'Río Gallegos', 'Rosario', 'Salta', 'San Carlos de Bariloche', 'San Juan',
    'San Luis', 'San Miguel de Tucumán', 'San Salvador de Jujuy', 'Santa Fe', 'Santa Rosa',
    'Santiago del Estero', 'Ushuaia', 'Viedma',
  ],
  'Brasil': ciudadesBrasil,
  'Chile': [
    'Santiago', 'Antofagasta', 'Arica', 'Concepción', 'Iquique', 'La Serena', 'Puerto Montt',
    'Punta Arenas', 'Rancagua', 'Talca', 'Temuco', 'Valparaíso', 'Viña del Mar',
  ],
  'Paraguay': [
    'Asunción', 'Capiatá', 'Ciudad del Este', 'Encarnación', 'Luque', 'Pedro Juan Caballero', 'San Lorenzo',
  ],
  'Bolivia': ['La Paz', 'Cochabamba', 'El Alto', 'Oruro', 'Potosí', 'Santa Cruz de la Sierra', 'Sucre', 'Tarija'],
  'Perú': ['Lima', 'Arequipa', 'Chiclayo', 'Cusco', 'Iquitos', 'Piura', 'Trujillo'],
  'Colombia': ['Bogotá', 'Barranquilla', 'Bucaramanga', 'Cali', 'Cartagena', 'Medellín', 'Pereira'],
  'Ecuador': ['Quito', 'Cuenca', 'Guayaquil'],
  'Venezuela': ['Caracas', 'Barquisimeto', 'Maracaibo', 'Valencia'],
  'México': ['Ciudad de México', 'Cancún', 'Guadalajara', 'Mérida', 'Monterrey', 'Puebla', 'Tijuana'],
  'España': ['Madrid', 'Barcelona', 'Bilbao', 'Málaga', 'Sevilla', 'Valencia', 'Zaragoza'],
  'Estados Unidos': ['Chicago', 'Houston', 'Los Ángeles', 'Miami', 'Nueva York', 'Orlando'],
};

/// Opcion para quien vive en una ciudad que no esta en la lista.
const String otraCiudad = 'Otra ciudad';
