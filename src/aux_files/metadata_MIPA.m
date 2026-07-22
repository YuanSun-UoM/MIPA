function cfg = metadata_MIPA(cfg)
%oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
% Add fixed MIPA product metadata to cfg
%
% Usage:
%   cfg = config_MIPA();
%   cfg = metadata_MIPA(cfg);
%oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo

    if nargin < 1 || isempty(cfg)
        cfg = struct();
    end

    % ---------------------------------------------------------------------
    % Fixed processing metadata
    % ---------------------------------------------------------------------
    cfg.source = 'Ground Based Aerosol Remote Sensing Measurements, Radiosounding Systems';

    cfg.references = ['D''Amico, G.; Arienzo, A.; Vivone, G.; Amodeo, A.; ' ...
                      'Cardellicchio, F.; Gumà-Claramunt, P.; De Rosa, B.; ' ...
                      'Di Girolamo, P.; Gandolfi, I.; Giunta, A.; et al. ' ...
                      'Atmospheric Boundary Layer Height Estimation from Lidar Observations: ' ...
                      'Assessment and Validation of MIPA Algorithm. Remote Sens. 2025, 17, 2748. ' ...
                      'https://doi.org/10.3390/rs17162748'];

    cfg.citation = cfg.references;

    cfg.data_processing_institution = ...
        'Consiglio Nazionale delle Ricerche - Istituto di Metodologie per l’Analisi Ambientale (CNR-IMAA)';

    cfg.data_processing_institution_ror = 'https://ror.org/024ye7w89';

    cfg.PI = 'Giuseppe D''Amico';

    cfg.PI_affiliation = ...
        'Consiglio Nazionale delle Ricerche - Istituto di Metodologie per l’Analisi Ambientale';

    cfg.PI_affiliation_acronym = 'CNR-IMAA';

    cfg.PI_address = 'Contrada S.Loja, Zona Industriale - Tito Scalo 85050 Potenza';

    cfg.PI_phone = '+39 0971 427297';

    cfg.PI_email = 'giuseppe.damico@cnr.it';

    cfg.PI_orcid = 'https://orcid.org/0000-0001-6627-2517';

    cfg.acknowledgements = ['EU - Next Generation EU Mission 4, Component 2 - ' ...
                            'CUP B53C22002150006 - Project IR0000032 - ITINERIS - ' ...
                            'Italian Integrated Environmental Research Infrastructures System'];

    cfg.processor_name = 'MIPA';
    cfg.processor_longname = 'Morphological Image Processing Approach';

    % ---------------------------------------------------------------------
    % Processor version
    % ---------------------------------------------------------------------
    if ~isfield(cfg, 'processor_version') || isempty(cfg.processor_version)
        cfg.processor_version = '1.0.0';
    end
end