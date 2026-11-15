/// Paises y ciudades para los menus desplegables del registro y del perfil.
/// Para agregar una ciudad o un pais, editar este mapa.
const Map<String, List<String>> ciudadesPorPais = {
  'Uruguay': [
    'Montevideo', 'Artigas', 'Canelones', 'Ciudad de la Costa', 'Colonia del Sacramento', 'Durazno',
    'Florida', 'Fray Bentos', 'Las Piedras', 'Maldonado', 'Melo', 'Mercedes', 'Minas', 'Pando',
    'Paysandú', 'Punta del Este', 'Rivera', 'Rocha', 'Salto', 'San José de Mayo', 'Tacuarembó',
    'Treinta y Tres', 'Trinidad',
  ],
  'Argentina': [
    'Buenos Aires (CABA)', 'Bahía Blanca', 'Catamarca', 'Comodoro Rivadavia', 'Córdoba', 'Corrientes',
    'Formosa', 'La Plata', 'La Rioja', 'Mar del Plata', 'Mendoza', 'Neuquén', 'Paraná', 'Posadas',
    'Rawson', 'Resistencia', 'Río Gallegos', 'Rosario', 'Salta', 'San Carlos de Bariloche', 'San Juan',
    'San Luis', 'San Miguel de Tucumán', 'San Salvador de Jujuy', 'Santa Fe', 'Santa Rosa',
    'Santiago del Estero', 'Ushuaia', 'Viedma',
  ],
  'Brasil': [
    'São Paulo', 'Belém', 'Belo Horizonte', 'Brasília', 'Campinas', 'Chuí', 'Curitiba', 'Florianópolis',
    'Fortaleza', 'Goiânia', 'João Pessoa', 'Maceió', 'Manaus', 'Natal', 'Pelotas', 'Porto Alegre',
    'Recife', 'Rio de Janeiro', 'Salvador', 'Santana do Livramento', 'Santos', 'Vitória',
  ],
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
