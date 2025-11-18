import React, { useEffect, useState } from "react";
import mermaid from "mermaid";

// Mermaid setup
mermaid.initialize({
  startOnLoad: false,
  securityLevel: "loose",
  theme: "base",
  themeVariables: {
    fontFamily:
      "ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, Noto Sans, 'Apple Color Emoji', 'Segoe UI Emoji'",
  },
});

const highLevelDiagram = `flowchart LR
  %% High-level view: 9 blocks
  U[Channels and Users]
  GW[API Gateway]
  LC[Licensing and Credentialing Core]
  PR[Policy and Rules]
  CS[Case and Sanctions]
  DI[Data and Integration]
  BP[Billing and Payments]
  SC[Security and Compliance]
  EX[External Exchanges]

  U --> GW --> LC
  PR --> LC
  CS <--> LC
  LC <--> DI
  LC --> BP
  DI <--> EX

  %% Security associations
  SC --- U
  SC --- GW
  SC --- LC
  SC --- DI
  SC --- BP
  SC --- EX`;

const detailedDiagram = `flowchart LR
  %% Simplified for broad Mermaid compatibility: no classDefs, no class tags, no HTML breaks

  %% CHANNELS
  subgraph CH[Channels]
    C1[Web and Mobile Self-Service Portal]
    C2[Field Office Workstations]
    C3[CSR and Contact Center Console]
    C4[Third-Party and Partner Portal]
    C5[Verification and Data Query Portal]
  end

  %% CORE LICENSING
  subgraph CORE[Core Licensing Services]
    MDM[Customer Master and Driver History Record]
    IDV[Identity Proofing and Document Capture]
    BIO[Photo, Signature and Facial Matching]
    APPT[Appointments and Queue Management]
    KT[Knowledge Testing - CBT and item bank]
    RT[Road Test Scheduling and Scoring]
    ISS[Credential Issuance and Card Personalization]
    MDL[mDL Issuance and Lifecycle]
    LCM[Lifecycle Management - renew, replace, address]
    SAN[Sanctions, Points and Withdrawals]
    POL[Policy Engine - eligibility, sanctions, fees]
    PEDIT[Policy Editor]
    CASE[Case Management - fraud, medical, investigations]
    NOTIF[Notifications - email, SMS, mail]
  end

  %% DATA AND INTEGRATION
  subgraph DI[Data and Integration]
    API[API Gateway]
    ESB[Event Bus and Streaming]
    ETL[Data Sharing Pipelines - ETL and ELT]
    DWH[Analytics Warehouse or Lakehouse]
    AUD[Immutable Audit and Access Logs]
    RPT[Operational and Regulatory Reporting]
    DQI[Data Query Interface - internal and external]
  end

  %% SECURITY AND COMPLIANCE
  subgraph SEC[Security and Compliance]
    IAM[IAM - SSO, MFA, RBAC or ABAC]
    ENC[Encryption at Rest and In Transit]
    KMS[Secrets and Key Management - FIPS crypto]
    PRIV[Privacy and DPPA Controls]
    SIEM[Monitoring, SIEM, Threat Detection]
    GOV[Standards and Audits - REAL ID, NIST 800-63, CJIS]
  end

  %% BILLING AND PAYMENTS
  subgraph PAY[Billing and Payments]
    FEES[Fee Calculation, Waivers, Surcharges]
    PAYORCH[Payment Orchestration - Card, ACH, Cash, Check]
    PCI[PCI DSS Cardholder Data Environment]
    AR[Reconciliation, Refunds, General Ledger Posting]
  end

  %% EXTERNAL EXCHANGES
  subgraph EXT[External Systems and Exchanges]
    S2S[AAMVA S2S and DHR]
    CDLIS[CDLIS]
    NDR[NDR and PDPS]
    SSOLV[SSA SSOLV - SSN verification]
    SAVE[SAVE - lawful status]
    EVVE[EVVE - birth and death verification]
    DLDV[DLDV - industry DL or ID verification]
    DIAE[DIAE - digital image exchange]
    NLETS[NLETS and NCIC - law enforcement read only]
    COURT[Courts and eCitation Feeds]
    CIVIC[Voter, Selective Service, Organ Donor Feeds]
    BUREAU[Card Production Vendor]
    MDLVER[mDL Verifiers]
  end

  %% CHANNEL FLOWS
  C1 --> API
  C2 --> API
  C3 --> API
  C4 --> API
  C5 --> DQI

  %% API TO CORE
  API --> IDV
  API --> APPT
  API --> KT
  API --> RT
  API --> ISS
  API --> MDL
  API --> LCM
  API --> SAN
  API --> CASE
  API --> NOTIF
  API --> MDM
  API --> FEES
  API --> DQI

  %% CORE INTERNAL FLOWS
  BIO --> IDV
  IDV --> MDM
  KT --> MDM
  RT --> MDM
  ISS --> MDM
  MDL --> MDM
  LCM --> MDM
  SAN --> MDM
  PEDIT --> POL
  POL --> ISS
  POL --> LCM
  POL --> SAN
  POL --> FEES

  %% DATA AND INTEGRATION FLOWS
  IDV --> ESB
  ISS --> ESB
  LCM --> ESB
  SAN --> ESB
  CASE --> ESB
  NOTIF --> ESB
  ESB --> ETL
  ETL --> DWH
  DWH --> RPT
  DQI <--> RPT
  API --> AUD
  DQI --> AUD
  ESB --> AUD

  %% SECURITY OVERLAYS (logical associations)
  C1 --- IAM
  C2 --- IAM
  C3 --- IAM
  C4 --- IAM
  C5 --- IAM
  API --- ENC
  PCI --- KMS
  ESB --- SIEM
  IDV --- GOV
  ISS --- GOV
  LCM --- GOV
  SAN --- GOV
  DQI --- PRIV
  DWH --- PRIV
  ETL --- PRIV

  %% PAYMENTS
  FEES --> PAYORCH
  PAYORCH --> PCI
  PAYORCH --> AR

  %% EXTERNAL LINKAGES (via API or ESB and secured per SEC)
  IDV --> SSOLV
  IDV --> SAVE
  IDV --> EVVE
  IDV --> DIAE
  DQI --> NLETS
  SAN --> S2S
  MDM --> S2S
  SAN --> NDR
  MDM --> CDLIS
  COURT --> SAN
  LCM --> CIVIC
  ISS --> BUREAU
  MDL --> MDLVER
  C4 <--> DLDV`;

export default function DMVMermaidRender() {
  const [mode, setMode] = useState<"high" | "detailed">("high");
  const [svg, setSvg] = useState("");
  const [error, setError] = useState<string | null>(null);

  const currentDiagram = mode === "high" ? highLevelDiagram : detailedDiagram;

  const renderDiagram = async () => {
    try {
      const { svg } = await mermaid.render("dmvDiagram", currentDiagram);
      setSvg(svg);
      setError(null);
    } catch (e: any) {
      setError(e?.message || "Mermaid rendering error");
      setSvg("");
    }
  };

  useEffect(() => {
    renderDiagram();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [mode]);

  const downloadSvg = () => {
    if (!svg) return;
    const blob = new Blob([svg], { type: "image/svg+xml" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = mode === "high" ? "dmv-architecture-high-level.svg" : "dmv-licensing-architecture-detailed.svg";
    a.click();
    URL.revokeObjectURL(url);
  };

  const copyMermaid = async () => {
    try {
      await navigator.clipboard.writeText(currentDiagram);
    } catch {}
  };

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 p-6">
      <div className="mx-auto max-w-7xl space-y-4">
        <div className="flex items-center justify-between gap-4">
          <h1 className="text-xl font-semibold tracking-tight">
            DMV Licensing Platform | {mode === "high" ? "High-level view" : "Detailed view"}
          </h1>
          <div className="flex items-center gap-2">
            <div className="flex rounded-xl overflow-hidden border border-slate-200">
              <button
                onClick={() => setMode("high")}
                className={`px-3 py-2 text-sm ${mode === "high" ? "bg-blue-600 text-white" : "bg-white hover:bg-slate-100"}`}
              >
                High-level
              </button>
              <button
                onClick={() => setMode("detailed")}
                className={`px-3 py-2 text-sm ${mode === "detailed" ? "bg-blue-600 text-white" : "bg-white hover:bg-slate-100"}`}
              >
                Detailed
              </button>
            </div>
            <button onClick={copyMermaid} className="px-3 py-2 rounded-xl bg-white border border-slate-200 shadow-sm hover:bg-slate-100 text-sm">
              Copy Mermaid
            </button>
            <button onClick={renderDiagram} className="px-3 py-2 rounded-xl bg-white border border-slate-200 shadow-sm hover:bg-slate-100 text-sm">
              Re-render
            </button>
            <button onClick={downloadSvg} className="px-3 py-2 rounded-xl bg-blue-600 text
